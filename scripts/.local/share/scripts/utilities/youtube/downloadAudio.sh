#!/bin/sh
youtube-dl -x --audio-format mp3 -o "$HOME/Music/Youtube/%(title)s-%(id)s.%(ext)s"  $1

