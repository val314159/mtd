'''
'''
from __future__ import annotations
from typing import TYPE_CHECKING

import os

if TYPE_CHECKING:
    from .models import Workflow, Task, Relation, Job


class TaskPeer:

    def __init__(self, peer: Task):
        self._peer = peer
        return

    def in_links(self):
        return self._peer.in_links()

    def out_links(self):
        return self._peer.out_links()

    def __getattr__(self, name):
        if name.startswith('_'):
            raise AttributeError(name)
        try:
            return self._peer.meta[name]
        except KeyError:
            raise AttributeError(name) from None

    def _get(self, name):
        return self._peer.meta.get(name)

    pass


class Watcher(TaskPeer):

    WATCHER = True

    pass


class JobRunner(TaskPeer):

    WATCHER = False

    pass


class Any(Watcher):

    STYLE = 'circle plus'

    def satisfies(self):
        is_satisfied = False
        for in_link in self._peer.in_links():
            if in_link.satisfied():
                is_satisfied = True
                # don't break, we'll give all the dependencies a chance to run
                pass
            pass
        return is_satisfied

    pass


class All(Watcher):

    STYLE = 'circle dot'

    def satisfies(self):
        is_satisfied = True
        for in_link in self._peer.in_links():
            if not in_link.satisfied():
                is_satisfied = False
                # don't break, we'll give all the dependencies a chance to run
                pass
            pass
        return is_satisfied

    pass


class Complete(All):

    STYLE = 'double circle'
        
    pass


class Decision(Watcher):

    STYLE = 'diamond'
    
    pass


class YesNoDecision(Decision):

    def yes(self):
        return self.value == 'yes'

    def no(self):
        return self.value == 'no'

    pass


class FileExists(Watcher):

    def exists(self):
        try:
            os.stat(self.path)
            return True
        except FileNotFoundError:
            return False
        pass

    pass
