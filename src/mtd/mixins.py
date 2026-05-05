class WorkflowMixin:
    def add_task(self, task_id: str, label: str, group: str):
        from .models import Task, TaskState

        return Task(
            workflow=self,
            id=task_id,
            display_name=label,
            task_state=TaskState.NOTSTARTED,
            python_class=f"examples.{task_id}",
            meta={"group": group},
        )
    pass

class TaskMixin:
    def link(self, *targets, kind: str = "satisfies") -> None:
        from .models import Relation

        self.relations_workflow_sources.extend(
            Relation(workflow_target=target, kind=kind)
            for target in targets
        )
    pass

class JobMixin:
    pass

class RelationMixin:
    pass
