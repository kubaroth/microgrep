# Overview

A plugin which wraps 'grep' command to perform string searches and redirects results in a new buffer.

# Features

- Fast file visiting using <tab> key.
- For long running searches, matching results are returned immediately.
- Custom color scheme for improved readability.

# Commands

 `grep search_key` - Starts grep the current directory and searches for a specified string. The process runs in the background, matching results are displayed in a new buffer.
Hitting *<tab>* on any line which contains a valid file path opens a preview in a temporary horizontal split.

`greppath` - stores file paths of the active buffer in the system clipboard. The current typical use case is to use it as a shorthand to open files with long path in a new buffer.

`greprun` Runs any arbitrary command and redirect the output into a new buffer. ie.: 'greprun ls -ltr ../'
