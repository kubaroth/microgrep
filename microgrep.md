# Overview

Plugin which wraps grep command to perform string searches and display results in a new buffer. 

# Features

- fast preview of results using <tab> key
- grep process asynchronously updates results buffer
- custom color scheme for better readability

# Commands

 `grep search_key` - start a search for a specified string using current directory as the root. The process runs asynchronously, matching results are displayed in a new tab.
Hitting *<tab>* on any line  which contains a valid file path will open a preview in a horizontal split.

`greppath` - stores file path of the active buffer in the system clipboard. The curernt use case is in combination with grep, as a shorthand to open files deep file paths.
