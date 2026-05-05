CREATE TABLE workflows (
    id text PRIMARY KEY,
    display_name text,
    meta jsonb NOT NULL DEFAULT '{}'::jsonb
);
CREATE TABLE tasks (
    id text PRIMARY KEY,
    display_name text,
    workflow_id text NOT NULL REFERENCES workflows(id) ON DELETE CASCADE,
    meta jsonb NOT NULL DEFAULT '{}'::jsonb
);
CREATE TABLE dependencies (
    -- a child depends on the parent
    -- this is a dotted arrow from child to parent
    target_task text NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    depends_on  text NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    PRIMARY KEY (target_task, depends_on)
);
CREATE TABLE jobs (
    id text PRIMARY KEY,
    task_id text NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
    celery_task_id text NOT NULL,
    meta jsonb NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX tasks_workflow_id_idx ON tasks(workflow_id);
CREATE INDEX depends_on_idx ON dependencies(depends_on);
CREATE INDEX jobs_task_id_idx ON jobs(task_id);
CREATE UNIQUE INDEX jobs_celery_task_id_idx ON jobs(celery_task_id);
