# How You can update this documentation

Instructions on how to propose corrections and add new instructions to this
repositopry.

## Quick and dirty

Mail to <juha.lento@csc.fi> :)

## Developing this documentation

In case of more involved document development...

Also, these instructions can be used in general with GitHub forks.

### Overview

There will be basically three versions of "atm-doc" repository involved in the process:

1. The main "upstream" repository
   [atm-doc](https://github.com/jlento/atm-doc)

2. Your own "atm-doc" GitHub repository that is forked from the
   main upstream repository

3. The working copy of your own repository in the local disc

Sounds complicated, but is not that bad and works in practice. Also,
this procedure is the standard for all simple git/GitHub based
software projects.


### First time

- Get a GitHub account and login, https://github.com

- Go to this repository, https://github.com/jlento/atm-doc, and fork
  it (there is a green button on the page)

- Go to your forked repository and clone it to your local disc (there
  is a green "clone" button where you get the URL of the repository)

    git clone URL

- Make your changes in the local disc clone, commit them, and push
  them to your own GitHub repository using `git
  status/add/commit/push/...`

- Make a pull request to the upstream repository (there is "new
  pull request" button on the page)


### Second time

- synchronize your fork with the upstream repository before making new
  changes, https://help.github.com/articles/syncing-a-fork

- "Pull" the updated version of your own repository

    git pull

- Make the changes, commit and push and make a pull request as in the
  first time
