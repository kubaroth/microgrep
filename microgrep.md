# Overview

A plugin which wraps 'grep' command to perform string searches and display results in a new buffer.

# Features

- Fast results file inspection using <tab> key.
- For long running searches, matching results are returned immediately.
- Custom color scheme for improved readability.

# Commands

 `grep search_key` - Starts the current directory where Micro was launched and searches for a specified string. The process runs in the background, matching results are displayed in a new tab.
Hitting *<tab>* on any line which contains a valid file path opens a preview in a temporary horizontal split.

`greppath` - stores file paths of the active buffer in the system clipboard. The current use case is to use it in combination with grep, as a shorthand to open files with long paths.
