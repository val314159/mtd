'''
'''

import os


class TaskPeer:

    def __init__(self, peer):
        self.peer = peer
        return

    pass


class Decision(TaskPeer):

    def __init__(self, peer):
        super().__init__(peer)
        self.value = None
        pass

    pass


class YesNoDecision(Decision):

    def yes(self):
        return self.value == 'yes'

    def no(self):
        return self.value == 'no'

    pass


class FileExists(TaskPeer):

    def __init__(self, peer, path):
        super().__init__(peer)
        self.path = path
        return

    def exists(self):
        try:
            os.stat(self.path)
            return True
        except FileNotFoundError:
            return False
        pass

    pass
