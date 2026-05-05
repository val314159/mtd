
CREATE TABLE WORKFLOWS (
       -- workflows
       PRIMARY text id;
       JSONP meta;
);

CREATE TABLE TASKS (
       -- tasks
       PRIMARY text id;
       JSONP meta;
       WORKFLOWS workflow FOREIGN KEY;
);

CREATE TABLE DEPENDENCIES (
       -- dependencies
       TASKS name  INDEXED FOREIGN KEY;
       TASKS value INDEXED FOREIGN KEY;
);

CREATE TABLE JOBS (
       -- jobs are celery tasks
       PRIMARY text id;
       TEXT job_id;
       JSONP meta;
       FOREIGN KEY tasks task;
);
