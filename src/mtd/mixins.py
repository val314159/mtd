'''
'''

from .models import Workflow, Task, Relation, Job


class WorkflowMixin:
    
    def add_task(self: Workflow, task_id: str, label: str, group: str):
        from .models import Task, TaskState

        return Task(
            workflow=self,
            id=task_id,
            display_name=label,
            task_state=TaskState.NOTSTARTED,
            python_class=f"examples.{task_id}",
            meta={"group": group},
        )

    def print_graph(self: Workflow) -> None:
        print(f"workflow: {self.id} ({self.display_name})")
        for task in self.tasks:
            targets = ", ".join(
                f"{relation.workflow_target.id} [{relation.kind}]"
                for relation in task.relations_workflow_sources
            ) or "-"
            print(f"  {task.id:15s} -> {targets}")
            pass
        print("\ndigraph cool_graph {")
        for task in self.tasks:
            print(f'  "{task.id}" [label="{task.display_name}"];')
            pass
        for task in self.tasks:
            for relation in task.relations_workflow_sources:
                print(
                    f'  "{task.id}" -> "{relation.workflow_target.id}" '
                    f'[label="{relation.kind}"];'
                )
                pass
            pass
        print("}")
        return

    pass


class TaskMixin:

    def link(self: Task, *targets, kind: str = "satisfies") -> None:
        self.relations_workflow_sources.extend(
            Relation(workflow_target=target, kind=kind)
            for target in targets
        )
        return
    
    pass


class RelationMixin:

    pass


class JobMixin:

    def update_job_state(self: Job, new_state: str) -> None:
        return
    
    pass
