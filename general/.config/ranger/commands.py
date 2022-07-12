from ranger.api.commands import *
from ranger.container.file import File
from ranger.ext.get_executables import get_executables
import subprocess
import os

import re
import ranger.api


# test = 0

# test = self.fm.execute_console("set viewmode multipane")

# if self.fm.thisdir == "drive":
#     test = self.fm.execute_console("echo " + self.fm.thisdir, stdout=subprocess.PIPE)
# self.fm.execute_command("viewmode multipane")
# else:
# self.fm.execute_command("viewmode miller")


HOOK_READY_OLD = ranger.api.hook_ready

# example hook
# https://github.com/ranger/ranger/blob/master/examples/plugin_fasd_add.py


def hook_ready(fm):
    def drive_toggle():
        """ changes viewmode when entering the remotes folder """

        history = fm.thistab.history.history
        prev_dir = None
        if len(history) > 1:
            prev_dir = history[-2]

        viewmode = fm.settings["viewmode"]
        cur_path = fm.thisdir.path
        remotes_path = os.getenv("REMOTES")
        playground_path = os.getenv("PLAYGROUND")

        sub_folders = ['SSH']
        paths_creator = lambda main_folder: [ f'{main_folder}/{sub_folder}' for sub_folder in sub_folders ]
        path_check = lambda x, y: x in y

        if not remotes_path and not playground_path:
            return

        # add new paths here
        # paths = [remotes_path, *paths_creator(playground_path)]
        paths = [remotes_path]

        paths_exist = [path_check(path, cur_path) for path in paths ]
        if any(paths_exist) :
            if viewmode == "miller":
                fm.execute_console("set viewmode multipane")
        else:
            if prev_dir:
                prev_dir_exists = [path_check(path, str(prev_dir)) for path in paths ]
                if any(prev_dir_exists):
                    if viewmode != "miller":
                        fm.execute_console("set viewmode miller")

    drive_toggle()
    fm.signal_bind("cd", drive_toggle)
    return HOOK_READY_OLD(fm)


ranger.api.hook_ready = hook_ready


class fzf_select(Command):
    """
    :fzf_select

    Find a file using fzf.

    With a prefix argument select only directories.

    See: https://github.com/junegunn/fzf
    """

    def execute(self):

        if self.quantifier:
            # match only directories
            command = "find -L . \( -path '*/\.*' -o -fstype 'dev' -o -fstype 'proc' \) -prune \
            -o -type d -print 2> /dev/null | sed 1d | cut -b3- | fzf +m"
        else:
            # match files and directories
            # command = "find -L . \( -path '*/\.*' -o -fstype 'dev' -o -fstype 'proc' \) -prune \
            # -o -print 2> /dev/null | sed 1d | cut -b3- | fzf +m"
            command = "fzf +m"
        fzf = self.fm.execute_command(command, universal_newlines=True, stdout=subprocess.PIPE)
        stdout, stderr = fzf.communicate()
        if fzf.returncode == 0:
            fzf_file = os.path.abspath(stdout.rstrip("\n"))
            if os.path.isdir(fzf_file):
                self.fm.cd(fzf_file)
            else:
                self.fm.select_file(fzf_file)


class rga_select(Command):
    """

    Find a file using rg and fzf.

    See: https://github.com/junegunn/fzf
    """

    def execute(self):
        import subprocess
        import os.path

        command = """
            RG_PREFIX="rga --files-with-matches"
            local file
            file="$(
                FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
                        fzf --height=40 --sort --preview="[[ ! -z {} ]] && bat --color always {} | rga --pretty --context 5 {q} 2>/dev/null" \
                                --phony -q "$1" \
                                --bind "change:reload:$RG_PREFIX {q}" \
                                --preview-window="70%:wrap"
        )" &&
        echo "$file" """

        # command = """
        #     RG_PREFIX="rga --files-with-matches"
        #     local file
        #     file="$(
        #         FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
        #                 fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
        #                         --phony -q "$1" \
        #                         --bind "change:reload:$RG_PREFIX {q}" \
        #                         --preview-window="70%:wrap"
        # )" &&
        # echo "opening $file" &&
        # xdg-open "$file" """

        fzf = self.fm.execute_command(command, universal_newlines=True, stdout=subprocess.PIPE)
        stdout, stderr = fzf.communicate()
        if fzf.returncode == 0:
            fzf_file = os.path.abspath(stdout.rstrip("\n"))
            self.fm.select_file(fzf_file)
            # self.fm.execute_command("xdg-open " + fzf_file)
            self.fm.execute_command("nvim " + fzf_file)


class rg_select(Command):
    """

    Find a file using rg and fzf.

    See: https://github.com/junegunn/fzf
    """

    def execute(self):
        import subprocess
        import os.path

        command = """
            RG_PREFIX="rga --files-with-matches"
            local file
            file="$(
                FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
                        fzf --height=40 --sort --preview="[[ ! -z {} ]] && bat --color always {} | rg --pretty --context 5 {q} 2>/dev/null" \
                                --phony -q "$1" \
                                --bind "change:reload:$RG_PREFIX {q}" \
                                --preview-window="70%:wrap"
        )" &&
        echo "$file" """

        # command = """
        #     RG_PREFIX="rga --files-with-matches"
        #     local file
        #     file="$(
        #         FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
        #                 fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
        #                         --phony -q "$1" \
        #                         --bind "change:reload:$RG_PREFIX {q}" \
        #                         --preview-window="70%:wrap"
        # )" &&
        # echo "opening $file" &&
        # xdg-open "$file" """

        fzf = self.fm.execute_command(command, universal_newlines=True, stdout=subprocess.PIPE)
        stdout, stderr = fzf.communicate()
        if fzf.returncode == 0:
            fzf_file = os.path.abspath(stdout.rstrip("\n"))
            self.fm.select_file(fzf_file)
            self.fm.execute_command("xdg-open " + fzf_file)


class YankContent(Command):
    """
    Copy the content of image file and text file with xclip
    """

    def execute(self):
        if "xclip" not in get_executables():
            self.fm.notify("xclip is not found.", bad=True)
            return

        arg = self.rest(1)
        if arg:
            if not os.path.isfile(arg):
                self.fm.notify("{} is not a file.".format(arg))
                return
            file = File(arg)
        else:
            file = self.fm.thisfile
            if not file.is_file:
                self.fm.notify("{} is not a file.".format(file.relative_path))
                return

        relative_path = file.relative_path
        cmd = ["xclip", "-selection", "clipboard"]
        if not file.is_binary():
            with open(file.path, "rb") as fd:
                subprocess.check_call(cmd, stdin=fd)
        elif file.image:
            cmd += ["-t", file.mimetype, file.path]
            subprocess.check_call(cmd)
            self.fm.notify("Content of {} is copied to x clipboard".format(relative_path))
        else:
            self.fm.notify("{} is not an image file or a text file.".format(relative_path))

    def tab(self, tabnum):
        return self._tab_directory_content()


class fzf_rga_documents_search(Command):
    """
    :fzf_rga_search_documents
    Search in PDFs, E-Books and Office documents in current directory.
    Allowed extensions: .epub, .odt, .docx, .fb2, .ipynb, .pdf.

    Usage: fzf_rga_search_documents <search string>
    """

    def execute(self):
        if self.arg(1):
            search_string = self.rest(1)
        else:
            self.fm.notify("Usage: fzf_rga_search_documents <search string>", bad=True)
            return

        import subprocess
        import os.path
        from ranger.container.file import File

        command = (
            "rga '%s' . --rga-adapters=pandoc,poppler | fzf +m | awk -F':' '{print $1}'"
            % search_string
        )
        fzf = self.fm.execute_command(command, universal_newlines=True, stdout=subprocess.PIPE)
        stdout, stderr = fzf.communicate()
        if fzf.returncode == 0:
            fzf_file = os.path.abspath(stdout.rstrip("\n"))
            self.fm.execute_file(File(fzf_file))


# class fd_search(Command):
#     """
#     :fd_search [-d<depth>] <query>
#     Executes "fd -d<depth> <query>" in the current directory and focuses the
#     first match. <depth> defaults to 1, i.e. only the contents of the current
#     directory.

#     See https://github.com/sharkdp/fd
#     """

#     SEARCH_RESULTS = deque()

#     def execute(self):
#         import re
#         import subprocess
#         from ranger.ext.get_executables import get_executables

#         self.SEARCH_RESULTS.clear()

#         if "fdfind" in get_executables():
#             fd = "fdfind"
#         elif "fd" in get_executables():
#             fd = "fd"
#         else:
#             self.fm.notify("Couldn't find fd in the PATH.", bad=True)
#             return

#         if self.arg(1):
#             if self.arg(1)[:2] == "-d":
#                 depth = self.arg(1)
#                 target = self.rest(2)
#             else:
#                 depth = "-d1"
#                 target = self.rest(1)
#         else:
#             self.fm.notify(":fd_search needs a query.", bad=True)
#             return

#         hidden = "--hidden" if self.fm.settings.show_hidden else ""
#         exclude = "--no-ignore-vcs --exclude '.git' --exclude '*.py[co]' --exclude '__pycache__'"
#         command = "{} --follow {} {} {} --print0 {}".format(fd, depth, hidden, exclude, target)
#         fd = self.fm.execute_command(command, universal_newlines=True, stdout=subprocess.PIPE)
#         stdout, _ = fd.communicate()

#         if fd.returncode == 0:
#             results = filter(None, stdout.split("\0"))
#             if not self.fm.settings.show_hidden and self.fm.settings.hidden_filter:
#                 hidden_filter = re.compile(self.fm.settings.hidden_filter)
#                 results = filter(
#                     lambda res: not hidden_filter.search(os.path.basename(res)), results
#                 )
#             results = map(
#                 lambda res: os.path.abspath(os.path.join(self.fm.thisdir.path, res)), results
#             )
#             self.SEARCH_RESULTS.extend(sorted(results, key=str.lower))
#             if len(self.SEARCH_RESULTS) > 0:
#                 self.fm.notify(
#                     "Found {} result{}.".format(
#                         len(self.SEARCH_RESULTS), ("s" if len(self.SEARCH_RESULTS) > 1 else "")
#                     )
#                 )
#                 self.fm.select_file(self.SEARCH_RESULTS[0])
#             else:
#                 self.fm.notify("No results found.")


# class fd_next(Command):
#     """
#     :fd_next
#     Selects the next match from the last :fd_search.
#     """

#     def execute(self):
#         if len(fd_search.SEARCH_RESULTS) > 1:
#             fd_search.SEARCH_RESULTS.rotate(-1)  # rotate left
#             self.fm.select_file(fd_search.SEARCH_RESULTS[0])
#         elif len(fd_search.SEARCH_RESULTS) == 1:
#             self.fm.select_file(fd_search.SEARCH_RESULTS[0])


# class fd_prev(Command):
#     """
#     :fd_prev
#     Selects the next match from the last :fd_search.
#     """

#     def execute(self):
#         if len(fd_search.SEARCH_RESULTS) > 1:
#             fd_search.SEARCH_RESULTS.rotate(1)  # rotate right
#             self.fm.select_file(fd_search.SEARCH_RESULTS[0])
#         elif len(fd_search.SEARCH_RESULTS) == 1:
#             self.fm.select_file(fd_search.SEARCH_RESULTS[0])
