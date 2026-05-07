from __future__ import annotations


class WorkflowMixin:
    pass

class TaskMixin:
    @property
    def peer(self):
        import tasks
        name = 'ManualTask'
        return getattr(tasks, name)(self)
    pass

class JobMixin:
    pass

class RelationMixin:
    pass

