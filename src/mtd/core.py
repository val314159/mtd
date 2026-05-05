import dataclasses as dc
import typing as t
from enum import StrEnum

class NYI(Exception): pass

class State(StrEnum):
    NOTSTARTED = "NOTSTARTED"
    RUNNING    = "RUNNING"
    BLOCKED    = "BLOCKED"
    DONE       = "DONE"

_dict = lambda: dc.field(default_factory=dict)

def _adjust_wf(self):
    if wf_id := hasattr(wf, 'id'):
        wf = self.wf
        self.wf = wf.id
        return wf
    try:
        return Workflow.__index__[self.wf]
    except:
        raise KeyError(self.wf, "workflow not found")
    pass

@dc.dataclass
class Workflow:
    __index__ = {}
    id: str
    tasks: dict[str, 'Task'] =_dict()
    artifacts: dict[str, 'Artifact'] =_dict()
    def __post_init__(self):
        class Lookup:
            def __init__(self, data): self.data = data
            def __getattr__(self, key): return self.data[key]        
            def __getitem__(self, key): return self.data[key]
            def __repr__(self): return repr(self.data)
            pass
        self.__index__[self.id] = self
        self.t = Lookup(self.tasks)
        self.a = Lookup(self.artifacts)
        if self.tasks:
            raise Exception('dont add tasks')
        if self.artifacts:
            raise Exception('dont add artifacts')
        pass
    pass

@dc.dataclass
class Task:
    __index__ = {}
    id: str
    wf: Workflow | None = None
    state: State = State.NOTSTARTED
    deps: dict[str, object] = _dict()
    inps: dict[str, object] = _dict()
    outs: dict[str, object] = _dict()
    def __getattr__(self, key):
        pass
    def __post_init__(self):
        self.__index__[self.id] = self
        if not self.wf:
            raise Exception('requires wf (workflow)')
        wf = _adjust_wf(self)        
        wf.tasks[self.id] = self
        pass
    def satisfied(self) -> bool:
        raise NYI
    def reason(self) -> str:
        raise NYI
    pass

@dc.dataclass
class Artifact:
    __index__ = {}
    id: str
    wf: Workflow | None = None
    task: Task | None = None
    def __post_init__(self):
        self.__index__[self.id] = self
        if not self.wf:
            raise Exception('requires wf (workflow)')
        self.task = getattr(self, 'id', self.task)
        wf = _adjust_wf(self)        
        wf.artifacts[self.id] = self
        pass
    pass

@dc.dataclass
class MyTask(Task):
    z: int = 1
    pass

@dc.dataclass
class MyArtifact(Artifact):
    z: int = 1
    pass

def test():
    print("run sanity tests")
    wf = Workflow("my_workflow1")

    t1 = Task("t1", wf=wf)
    print("t1", t1)
    t2 = Task("t2", wf="my_workflow1")
    print("t2", t2)

    print()
    
    a1 = MyArtifact("a1", wf=wf, task=t1)
    a2 = MyArtifact("a2", wf=wf)

    print("a1", a1)
    print("a2", a2)

    a3 = MyArtifact("a3", wf=wf)
    print("Z", a3)
    
    print(wf)

    print(wf.t.t1)

if __name__=='__main__':
    test()
