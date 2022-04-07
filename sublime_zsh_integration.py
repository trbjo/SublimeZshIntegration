from os import path
from sublime_plugin import WindowCommand
import subprocess

class GetSublimeFileNameCommand(WindowCommand):
    def run(self):
        buf = self.window.active_view().file_name()
        if buf is not None:
            f = open("/tmp/sublime_file_name", "w")
            f.write(buf)
            f.close()

class GetSublimeFolderNameCommand(WindowCommand):
    def run(self):
        buf = self.window.active_sheet().file_name()
        if buf is not None:
            f = open("/tmp/sublime_folder_name", "w")
            f.write(path.dirname(buf).replace(r' ', r'\ '))
            f.close()

class PasteZshCommand(WindowCommand):
    def run(self):
        subprocess.Popen(['/usr/bin/pkill', 'zsh', '--signal=USR2']).wait()
        subprocess.Popen(['swaymsg', '[title="^PopUp$"]', 'scratchpad', 'show,', 'fullscreen', 'disable,', 'move', 'position', 'center,', 'resize', 'set', 'width', '100ppt', 'height', '100ppt,', 'resize', 'shrink', 'up', '1100px,', 'resize', 'grow', 'up', '150px']).wait()

