from __future__ import annotations


def PeerTask:
    MANUAL = False
    WATCHER = False
    PROCESS = False
    COMPLETE = False
    pass


def ManualTask(PeerTask):
    MANUAL = True
    pass


def CompleteTask(PeerTask):
    COMPLETE = True
    pass
