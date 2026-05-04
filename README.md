# MTD (Making Things Done)

A lightweight workflow management system for orchestrating tasks and artifacts.

## Overview

MTD provides a clean, type-safe framework for defining workflows with tasks and artifacts. Built with Python dataclasses, it offers:

- **Workflow**: Container for tasks and artifacts
- **Task**: Units of work with dependencies, inputs, and outputs
- **Artifact**: Data produced or consumed by tasks

## Installation

```bash
# No external dependencies required
# Python 3.11+ recommended (for StrEnum support)
```

## Quick Start

```python
from core import Workflow, Task, MyArtifact

# Create a workflow
wf = Workflow("my_workflow")

# Create tasks
t1 = Task("t1", wf=wf)
t2 = Task("t2", wf=wf)

# Create artifacts
a1 = MyArtifact("a1", wf=wf, task=t1)

# Access via lookup
print(wf.t.t1)  # Access tasks by name
print(wf.a.a1)  # Access artifacts by name
```

## Core Concepts

### Workflow

A workflow is a container that holds tasks and artifacts. Each workflow is automatically registered in a global index.

```python
wf = Workflow("workflow_id")
wf.tasks  # Dict of tasks
wf.artifacts  # Dict of artifacts
```

### Task

Tasks represent units of work within a workflow. They have:

- `id`: Unique identifier
- `wf`: Parent workflow
- `state`: Current state (NOTSTARTED, RUNNING, BLOCKED, DONE)
- `deps`: Dependencies
- `inps`: Inputs
- `outs`: Outputs

```python
t = Task("task_id", wf=workflow, state=State.RUNNING)
```

### Artifact

Artifacts represent data produced or consumed by tasks.

```python
a = Artifact("artifact_id", wf=workflow, task=task)
```

## State Machine

Tasks follow a state machine:

| State | Description |
|------|-----|
| `NOTSTARTED` | Task hasn't begun |
| `RUNNING` | Task is executing |
| `BLOCKED` | Task waiting on dependencies |
| `DONE` | Task completed |

```python
from core import State

if task.state == State.DONE:
    print("Task completed!")
```

## Extending

### Custom Task

```python
from core import Task

@dc.dataclass
class MyTask(Task):
    z: int = 1  # Custom field
```

### Custom Artifact

```python
from core import Artifact

@dc.dataclass
class MyArtifact(Artifact):
    z: int = 1  # Custom field
```

## Usage Examples

### Basic Workflow

```python
wf = Workflow("data_pipeline")

# Create tasks
extract = Task("extract", wf=wf)
transform = Task("transform", wf=wf)
load = Task("load", wf=wf)

# Create artifacts
raw_data = MyArtifact("raw_data", wf=wf, task=extract)
processed_data = MyArtifact("processed_data", wf=wf, task=transform)
```

### Accessing Workflows

```python
# Access all workflows via the index
wf = Workflow.__index__["data_pipeline"]

# Access tasks/artifacts by name
print(wf.t.extract.id)
print(wf.a.raw_data.id)
```

### Task State Management

```python
# Check if task is done
if task.state == State.DONE:
    print("Task completed")

# Transition states
task.state = State.RUNNING
```

## Project Structure

```
mtd/
├── core.py       # Core classes (Workflow, Task, Artifact)
├── Makefile      # Build commands
└── README.md     # This file
```

## Running

```bash
# Run the test suite
make

# Or directly
python core.py
```

## Features

- ✅ Type-safe dataclass-based design
- ✅ Automatic workflow registration
- ✅ Convenient lookup access (`wf.t.task_name`)
- ✅ Extensible Task and Artifact classes
- ✅ State machine for task lifecycle
- ✅ Dependency tracking (deps, inps, outs)

## Roadmap

- [ ] Implement `satisfied()` method for dependency checking
- [ ] Implement `reason()` method for task status explanation
- [ ] Add artifact input/output connections
- [ ] Add workflow execution engine
- [ ] Add serialization/deserialization support

## License

MIT

## Author

Joel "val" Ward <val@ai.ccl.io>
