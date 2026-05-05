import os

from sqlalchemy import create_engine, delete
from sqlalchemy.orm import Session

from mtd.models import Task, TaskState, Workflow


def db_url() -> str:
    user = os.environ["PGUSER"]
    host = os.environ["PGHOST"]
    port = os.environ["PGPORT"]
    database = os.environ["PGDATABASE"]
    return f"postgresql+psycopg2://{user}@{host}:{port}/{database}"


def add_task(workflow: Workflow, task_id: str, label: str, group: str) -> Task:
    return Task(
        workflow=workflow,
        id=task_id,
        display_name=label,
        task_state=TaskState.NOTSTARTED,
        python_class=f"examples.{task_id}",
        meta={"group": group},
    )


def link(source: Task, *targets: Task) -> None:
    source.workflow_targets.extend(targets)


def build_workflow() -> Workflow:
    workflow = Workflow(
        id="cool_graph",
        display_name="Cool Graph",
        meta={"kind": "example", "shape": "fanout-diamond-merge"},
    )

    ingest = add_task(workflow, "ingest", "Ingest Raw Events", "input")
    profile = add_task(workflow, "profile", "Profile Inputs", "quality")
    clean = add_task(workflow, "clean", "Clean Records", "quality")
    enrich_users = add_task(workflow, "enrich_users", "Enrich Users", "enrich")
    enrich_accounts = add_task(workflow, "enrich_accounts", "Enrich Accounts", "enrich")
    score = add_task(workflow, "score", "Score Risk", "model")
    audit = add_task(workflow, "audit", "Audit Decisions", "control")
    publish = add_task(workflow, "publish", "Publish Snapshot", "output")
    notify = add_task(workflow, "notify", "Notify Subscribers", "output")

    link(ingest, profile, clean)
    link(profile, enrich_users)
    link(clean, enrich_users, enrich_accounts)
    link(enrich_users, score)
    link(enrich_accounts, score, audit)
    link(score, publish)
    link(audit, publish)
    link(publish, notify)

    return workflow


def print_graph(workflow: Workflow) -> None:
    print(f"workflow: {workflow.id} ({workflow.display_name})")
    for task in workflow.tasks:
        targets = ", ".join(target.id for target in task.workflow_targets) or "-"
        print(f"  {task.id:15s} -> {targets}")

    print("\ndigraph cool_graph {")
    for task in workflow.tasks:
        print(f'  "{task.id}" [label="{task.display_name}"];')
    for task in workflow.tasks:
        for target in task.workflow_targets:
            print(f'  "{task.id}" -> "{target.id}";')
    print("}")


def main() -> None:
    engine = create_engine(db_url())
    workflow = build_workflow()

    with Session(engine) as session:
        session.execute(delete(Workflow).where(Workflow.id == workflow.id))
        session.add(workflow)
        session.commit()

        saved = session.get(Workflow, workflow.id)
        if saved is None:
            raise RuntimeError("workflow was not saved")
        print_graph(saved)


if __name__ == "__main__":
    main()
