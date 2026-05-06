from __future__ import annotations

import os
import subprocess

from sqlalchemy import create_engine
from sqlalchemy.orm import Session

from mtd.celery_app import celery
from mtd.models import Job, JobState, TaskState


def db_url() -> str:
    user = os.environ["PGUSER"]
    host = os.environ["PGHOST"]
    port = os.environ["PGPORT"]
    database = os.environ["PGDATABASE"]
    return f"postgresql+psycopg2://{user}@{host}:{port}/{database}"


@celery.task(name="mtd.debug")
def debug():
    print("beat fired")


@celery.task(bind=True, name="mtd.run_make")
def run_make(self, workflow_id: str, task_id: str, target: str, cwd: str | None = None):
    engine = create_engine(db_url())

    with Session(engine) as session:
        job = session.get(Job, self.request.id)
        if job is None:
            raise RuntimeError(f"job not found for celery task {self.request.id}")

        task = job.task
        job.process_state = JobState.RUNNING
        task.task_state = TaskState.RUNNING
        session.commit()

        command = ["make", target]
        result = subprocess.run(
            command,
            cwd=cwd,
            text=True,
            capture_output=True,
            check=False,
        )

        job.meta = {
            **job.meta,
            "returncode": result.returncode,
            "stdout": result.stdout[-20000:],
            "stderr": result.stderr[-20000:],
        }

        if result.returncode == 0:
            job.process_state = JobState.SUCCESS
            task.task_state = TaskState.DONE
        else:
            job.process_state = JobState.FAILURE
            task.task_state = TaskState.BLOCKED

        session.commit()

        if result.returncode != 0:
            raise RuntimeError(
                f"make {target!r} failed with exit code {result.returncode}"
            )

        return {
            "workflow_id": workflow_id,
            "task_id": task_id,
            "target": target,
            "returncode": result.returncode,
        }
