CREATE TABLE workflows (
    id text PRIMARY KEY,
    display_name text,
    frozen bool NOT NULL DEFAULT FALSE,
    meta jsonb NOT NULL DEFAULT '{}'::jsonb
);
CREATE TABLE tasks (
    workflow_id text NOT NULL REFERENCES workflows(id) ON DELETE CASCADE,
    id text NOT NULL,
    display_name text,
    python_class text,
    task_state text NOT NULL,
    meta jsonb NOT NULL DEFAULT '{}'::jsonb,
    PRIMARY KEY (workflow_id, id)
);
CREATE TABLE dependencies (
    workflow_id text NOT NULL,
    target_task text NOT NULL,
    depends_on  text NOT NULL,
    PRIMARY KEY (workflow_id, target_task, depends_on),
    FOREIGN KEY (workflow_id, target_task)
        REFERENCES tasks(workflow_id, id) ON DELETE CASCADE,
    FOREIGN KEY (workflow_id, depends_on)
        REFERENCES tasks(workflow_id, id) ON DELETE CASCADE
);
CREATE INDEX depends_on_idx ON dependencies(workflow_id, depends_on);
CREATE TABLE jobs (
    id text PRIMARY KEY,
    task_workflow_id text NOT NULL,
    task_id text NOT NULL,
    celery_task_id text NOT NULL UNIQUE,
    process_state  text NOT NULL,
    meta jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at  timestamp DEFAULT now() NOT NULL,
    started_at  timestamp,
    finished_at timestamp,
    FOREIGN KEY (task_workflow_id, task_id)
        REFERENCES tasks(workflow_id, id) ON DELETE CASCADE
);
CREATE INDEX jobs_task_id_idx ON jobs(task_workflow_id, task_id);
