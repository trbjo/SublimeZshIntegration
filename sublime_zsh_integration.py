import platform
from os import getenv
from typing import Union

import sublime
from sublime import View
from sublime_api import view_file_name
from sublime_plugin import EventListener


class FileNameListener(EventListener):
    def get_subl_dir(self) -> Union[str, None]:
        os_type = platform.system()
        if not os_type:
            return None
        if os_type == "Linux":
            return getenv("XDG_RUNTIME_DIR")
        elif os_type == "Darwin":
            return getenv("TMPDIR")

    def __init__(self) -> None:
        SUBL_DIR = self.get_subl_dir()
        if not SUBL_DIR:
            return None
        self.myname = ""
        self.file = f"{SUBL_DIR}/sublime_file_name"
        self.f = open(self.file, "w")

    def on_activated_async(self, view: View):
        file_name: str = view_file_name(view.id())
        if file_name == self.myname:
            return
        if len(file_name) == 0:
            try:
                file_name = (
                    sublime.active_window().project_data()["folders"][0]["path"] + "/"
                )
            except KeyError:
                return
        self.myname = file_name
        self.f.seek(0)
        self.f.write(self.myname.replace(r" ", r"\ "))
        self.f.truncate()
