from .mixins import *
from typing import Optional
import datetime
import enum

from sqlalchemy import Boolean, Column, DateTime, Enum, ForeignKeyConstraint, Index, PrimaryKeyConstraint, Table, Text, UniqueConstraint, and_, text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship

class Base(DeclarativeBase):
    pass


class ProcessState(str, enum.Enum):
    PENDING = 'PENDING'
    RUNNING = 'RUNNING'
    SUCCESS = 'SUCCESS'
    FAILURE = 'FAILURE'


class TaskState(str, enum.Enum):
    NOTSTARTED = 'NOTSTARTED'
    RUNNING = 'RUNNING'
    BLOCKED = 'BLOCKED'
    DONE = 'DONE'


class Workflow(WorkflowMixin, Base):
    __tablename__ = 'workflows'
    __table_args__ = (
        PrimaryKeyConstraint('id', name='workflows_pkey'),
    )

    id: Mapped[str] = mapped_column(Text, primary_key=True)
    frozen: Mapped[bool] = mapped_column(Boolean, nullable=False, server_default=text('false'))
    meta: Mapped[dict] = mapped_column(JSONB, nullable=False, server_default=text("'{}'::jsonb"))
    display_name: Mapped[Optional[str]] = mapped_column(Text)

    tasks: Mapped[list['Task']] = relationship('Task', back_populates='workflow')


class Task(TaskMixin, Base):
    __tablename__ = 'tasks'
    __table_args__ = (
        ForeignKeyConstraint(['workflow_id'], ['workflows.id'], ondelete='CASCADE', name='tasks_workflow_id_fkey'),
        PrimaryKeyConstraint('workflow_id', 'id', name='tasks_pkey')
    )

    workflow_id: Mapped[str] = mapped_column(Text, primary_key=True)
    id: Mapped[str] = mapped_column(Text, primary_key=True)
    task_state: Mapped[TaskState] = mapped_column(Enum(TaskState, values_callable=lambda cls: [member.value for member in cls], name='task_state'), nullable=False, server_default=text("'NOTSTARTED'::task_state"))
    meta: Mapped[dict] = mapped_column(JSONB, nullable=False, server_default=text("'{}'::jsonb"))
    display_name: Mapped[Optional[str]] = mapped_column(Text)
    python_class: Mapped[Optional[str]] = mapped_column(Text)

    workflow: Mapped['Workflow'] = relationship('Workflow', back_populates='tasks')
    workflow_targets: Mapped[list['Task']] = relationship('Task', secondary='relations', primaryjoin=lambda: and_(Task.workflow_id == t_relations.c.workflow_id, Task.id == t_relations.c.source_id), secondaryjoin=lambda: and_(Task.workflow_id == t_relations.c.workflow_id, Task.id == t_relations.c.target_id), back_populates='workflow_sources')
    workflow_sources: Mapped[list['Task']] = relationship('Task', secondary='relations', primaryjoin=lambda: and_(Task.workflow_id == t_relations.c.workflow_id, Task.id == t_relations.c.target_id), secondaryjoin=lambda: and_(Task.workflow_id == t_relations.c.workflow_id, Task.id == t_relations.c.source_id), back_populates='workflow_targets')
    jobs: Mapped[list['Job']] = relationship('Job', back_populates='task')


class Job(JobMixin, Base):
    __tablename__ = 'jobs'
    __table_args__ = (
        ForeignKeyConstraint(['task_workflow_id', 'task_id'], ['tasks.workflow_id', 'tasks.id'], ondelete='CASCADE', name='jobs_task_workflow_id_task_id_fkey'),
        PrimaryKeyConstraint('id', name='jobs_pkey'),
        UniqueConstraint('celery_task_id', name='jobs_celery_task_id_key'),
        Index('jobs_task_id_idx', 'task_workflow_id', 'task_id')
    )

    id: Mapped[str] = mapped_column(Text, primary_key=True)
    task_workflow_id: Mapped[str] = mapped_column(Text, nullable=False)
    task_id: Mapped[str] = mapped_column(Text, nullable=False)
    celery_task_id: Mapped[str] = mapped_column(Text, nullable=False)
    process_state: Mapped[ProcessState] = mapped_column(Enum(ProcessState, values_callable=lambda cls: [member.value for member in cls], name='process_state'), nullable=False, server_default=text("'PENDING'::process_state"))
    meta: Mapped[dict] = mapped_column(JSONB, nullable=False, server_default=text("'{}'::jsonb"))
    created_at: Mapped[datetime.datetime] = mapped_column(DateTime(True), nullable=False, server_default=text('now()'))
    started_at: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))
    finished_at: Mapped[Optional[datetime.datetime]] = mapped_column(DateTime(True))

    task: Mapped['Task'] = relationship('Task', back_populates='jobs')


t_relations = Table(
    'relations', Base.metadata,
    Column('workflow_id', Text, primary_key=True),
    Column('source_id', Text, primary_key=True),
    Column('target_id', Text, primary_key=True),
    ForeignKeyConstraint(['workflow_id', 'source_id'], ['tasks.workflow_id', 'tasks.id'], ondelete='CASCADE', name='relations_workflow_id_source_id_fkey'),
    ForeignKeyConstraint(['workflow_id', 'target_id'], ['tasks.workflow_id', 'tasks.id'], ondelete='CASCADE', name='relations_workflow_id_target_id_fkey'),
    PrimaryKeyConstraint('workflow_id', 'source_id', 'target_id', name='relations_pkey'),
    Index('relations_idx', 'workflow_id', 'target_id')
)
