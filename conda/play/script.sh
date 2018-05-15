#!/bin/bash

requires figlet

# The Screen and the Stage

tmux set status off
tmux split-window -d -l 11
screen=$(tmux display -p -t 0 '#{pane_tty}')
stage=$(tmux display -p -t 1 '#{pane_tty}')

# Actors

koala () {
    local geometry="0 0 37 11 bottom-left"
    show "$geometry" -f koala <<<"$1" > $stage
    saywith espeak --stdin --stdout <<<"$1"
}

cow () {
    local geometry="37 0 43 11 bottom-left"
    show "$geometry" <<<"$1" > $stage
    saywith google_translate_speak <<<"$1"
}

# Let the play begin!

figlet -c Conda

koala; cow

koala "Hello dude! What's up?"

cow "I'm great! Thanks for asking. How are you? Any computer headaches?"

koala; cow

koala "Well, I'm trying to install this one app from sources to my computer, but
it depends on way too many other libraries. I'm giving up."

cow "Did you try to install it with the package manager that comes with your operating system?"

koala; cow

koala "OS package manager requires admin priviledges, which I do not have for this machine. Also, I'm afraid I may break somenthing."

koala; cow

cow "Did you check if there is a Conda package for your app? Conda does not require admin priviledges. Also, you can use any directory as an install root for the whole software stack."

koala; cow

cow "In fact, you can have multiple install roots. These are called virtual environments. Cool, right?"

sleep 1

koala; cow

cow "Oh, I almost forgot. Although virtual environments are not really sandboxes, most of the time you are quite safe with conda."

#echo "$(tput bold)$(tput setaf 4)ls -ltr$(tput sgr0)" > $screen
#sleep 1
#echo "$(ls -ltr)" > $screen

sleep 2

the-end
