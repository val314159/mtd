from __future__ import annotations

import os
import uuid

from sqlalchemy import select
from sqlalchemy.orm import object_session

from .models import Workflow, Task, Relation, Job, JobState


class TaskPeer:

    def __init__(self, peer: Task):
        self._peer = peer
        return

    def in_links(self):
        return self._peer.in_links()

    def out_links(self):
        return self._peer.out_links()

    def __getattr__(self, name):
        if name.startswith('_'):
            raise AttributeError(name)
        try:
            return self._peer.meta[name]
        except KeyError:
            raise AttributeError(name) from None

    def _get(self, name):
        return self._peer.meta.get(name)

    pass


class Watcher(TaskPeer):

    WATCHER = True

    pass


class JobRunner(TaskPeer):

    WATCHER = False

    pass


class MakeTask(JobRunner):
    '''
    use celery to run "make <task_id>"
    '''

    def run(self):
        from .celery_tasks import run_make

        target = self._get("target") or self._peer.id
        cwd = self._get("cwd")
        workflow_id = self._peer.workflow_id
        task_id = self._peer.id

        session = object_session(self._peer)
        if session is None:
            raise RuntimeError("MakeTask.run() requires a task attached to a session")

        locked_task = session.execute(
            select(Task)
            .where(Task.workflow_id == workflow_id, Task.id == task_id)
            .with_for_update() # THIS IS THE LOCK IT LIVES UNTIL COMMIT
        ).scalar_one()

        active_states = {JobState.PENDING, JobState.RUNNING}
        if any(job.job_state in active_states
               for job in locked_task.jobs):
            return

        job_id = uuid.uuid4().hex
        locked_task.jobs.append(
            Job(
                id=job_id,
                celery_task_id=job_id,
                job_state=JobState.PENDING,
                meta={"target": target, "cwd": cwd},
            )
        )
        session.commit()

        run_make.apply_async(
            task_id=job_id,
            args=(
                workflow_id,
                task_id,
                target,
                cwd,
            ),
        )
        return

    def start(self):
        self.run()
        return

    def success(self):
        job = self._latest_job()
        return job is not None and job.job_state == JobState.SUCCESS

    def failure(self):
        job = self._latest_job()
        return job is not None and job.job_state == JobState.FAILURE

    def _latest_job(self):
        jobs = list(self._peer.jobs)
        if not jobs:
            return None
        return max(
            jobs,
            key=lambda job: (
                job.created_at is not None,
                job.created_at,
                job.id,
            ),
        )

    pass


class Any(Watcher):

    STYLE = 'circle plus'

    def satisfies(self):
        is_satisfied = False
        for in_link in self._peer.in_links():
            if in_link.satisfied():
                is_satisfied = True
                # don't break, we'll give all the dependencies a chance to run
                pass
            pass
        return is_satisfied

    pass


class All(Watcher):

    STYLE = 'circle dot'

    def satisfies(self):
        is_satisfied = True
        for in_link in self._peer.in_links():
            if not in_link.satisfied():
                is_satisfied = False
                # don't break, we'll give all the dependencies a chance to run
                pass
            pass
        return is_satisfied

    pass


class Complete(All):

    STYLE = 'double circle'
        
    pass


class Decision(Watcher):

    STYLE = 'diamond'
    
    pass


class YesNoDecision(Decision):

    def yes(self):
        return self.value == 'yes'

    def no(self):
        return self.value == 'no'

    pass


class FileExists(Watcher):
    
    def exists(self):
        try:
            os.stat(self.path)
            return True
        except FileNotFoundError:
            return False
        pass

    def missing(self):
        return not self.exists()

    pass
