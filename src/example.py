import os

from sqlalchemy import create_engine, delete
from sqlalchemy.orm import Session

from mtd.models import Relation, Task, TaskState, Workflow


def db_url() -> str:
    user = os.environ["PGUSER"]
    host = os.environ["PGHOST"]
    port = os.environ["PGPORT"]
    database = os.environ["PGDATABASE"]
    return f"postgresql+psycopg2://{user}@{host}:{port}/{database}"


def build_workflow() -> Workflow:
    workflow = Workflow(
        id="cool_graph",
        display_name="Cool Graph",
        meta={"kind": "example", "shape": "fanout-diamond-merge"},
    )

    ingest = workflow.add_task("ingest", "Ingest Raw Events", "input")
    profile = workflow.add_task("profile", "Profile Inputs", "quality")
    clean = workflow.add_task("clean", "Clean Records", "quality")
    enrich_users = workflow.add_task("enrich_users", "Enrich Users", "enrich")
    enrich_accounts = workflow.add_task("enrich_accounts", "Enrich Accounts", "enrich")
    score = workflow.add_task("score", "Score Risk", "model")
    audit = workflow.add_task("audit", "Audit Decisions", "control")
    publish = workflow.add_task("publish", "Publish Snapshot", "output")
    notify = workflow.add_task("notify", "Notify Subscribers", "output")

    ingest.link(profile, clean)
    profile.link(enrich_users)
    clean.link(enrich_users, enrich_accounts)
    enrich_users.link(score)
    enrich_accounts.link(score, audit)
    score.link(publish)
    audit.link(publish)
    publish.link(notify)

    return workflow


def print_graph(workflow: Workflow) -> None:
    print(f"workflow: {workflow.id} ({workflow.display_name})")
    for task in workflow.tasks:
        targets = ", ".join(
            f"{relation.workflow_target.id} [{relation.kind}]"
            for relation in task.relations_workflow_sources
        ) or "-"
        print(f"  {task.id:15s} -> {targets}")

    print("\ndigraph cool_graph {")
    for task in workflow.tasks:
        print(f'  "{task.id}" [label="{task.display_name}"];')
    for task in workflow.tasks:
        for relation in task.relations_workflow_sources:
            print(
                f'  "{task.id}" -> "{relation.workflow_target.id}" '
                f'[label="{relation.kind}"];'
            )
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
