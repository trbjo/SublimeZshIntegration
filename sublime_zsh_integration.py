from os import path, getuid
from sublime_plugin import WindowCommand, EventListener
from sublime import View, Window
from sublime_api import view_file_name
import subprocess
import stat

class FileNameListener(EventListener):
    def __init__(self) -> None:
        self.user_id = getuid()
        self.myname = ''
        self.file = f"/tmp/sublime_{self.user_id}_file_name"
        self.directory = f"/tmp/sublime_{self.user_id}_folder_name"
        f = open(self.file, "w")
        f.write('')
        f.close()
        d = open(self.directory, "w")
        d.write('')
        d.close()


    def on_activated_async(self, view: View):
        file_name: str = view_file_name(view.id())
        if len(file_name) == 0:
            return
        if file_name == self.myname:
            return
        self.myname = file_name
        f = open(self.file, "w")
        f.write(self.myname)
        f.close()
        d = open(self.directory, "w")
        d.write(path.dirname(self.myname).replace(r' ', r'\ '))
        d.close()


class PasteZshCommand(WindowCommand):
    def run(self):
        subprocess.Popen(['/usr/bin/pkill', 'zsh', '--signal=USR2']).wait()
        subprocess.Popen(['swaymsg', '[title="^PopUp$"]', 'scratchpad', 'show,', 'fullscreen', 'disable,', 'move', 'position', 'center,', 'resize', 'set', 'width', '100ppt', 'height', '100ppt,', 'resize', 'shrink', 'up', '1100px,', 'resize', 'grow', 'up', '150px,', 'move', 'up', '22px,','move', 'left', '1px,', 'resize', 'grow', 'right', '2px']).wait()
