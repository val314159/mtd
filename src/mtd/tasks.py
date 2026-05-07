from __future__ import annotations


class PeerTask:
    MANUAL = False
    WATCHER = False
    PROCESS = False
    COMPLETE = False
    pass


class ManualTask(PeerTask):
    MANUAL = True
    pass


class WatcherTask(PeerTask):
    WATCHER = True
    pass


class ProcessTask(PeerTask):
    PROCESS = True
    pass


class CompleteTask(PeerTask):
    COMPLETE = True
    pass
