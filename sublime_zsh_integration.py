from os import path, getenv
from sublime_plugin import WindowCommand, EventListener
from sublime import View
from sublime_api import view_file_name
import subprocess

class FileNameListener(EventListener):
    def __init__(self) -> None:
        XDG_RUNTIME_DIR = getenv('XDG_RUNTIME_DIR')
        self.myname = ''
        self.file = f"{XDG_RUNTIME_DIR}/sublime_file_name"
        self.f = open(self.file, 'w')

    def on_activated_async(self, view: View):
        file_name: str = view_file_name(view.id())
        if len(file_name) == 0:
            return
        if file_name == self.myname:
            return
        self.myname = file_name
        self.f.seek(0)
        self.f.write(self.myname.replace(r' ', r'\ '))
        self.f.truncate()


class PasteZshCommand(WindowCommand):
    def run(self):
        subprocess.Popen(['/usr/bin/pkill', 'zsh', '--signal=USR2']).wait()
        subprocess.Popen(['swaymsg', '[title="^PopUp$"]', 'scratchpad', 'show,', 'fullscreen', 'disable,', 'move', 'position', 'center,', 'resize', 'set', 'width', '100ppt', 'height', '100ppt,', 'resize', 'shrink', 'up', '1100px,', 'resize', 'grow', 'up', '150px,', 'move', 'down', '1px,','move', 'left', '1px,', 'resize', 'grow', 'right', '2px']).wait()
