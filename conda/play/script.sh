#!/bin/bash

# The Screen and the Stage

tmux set status off
tmux split-window -d -l 11
screen=$(tmux display -p -t 0 '#{pane_tty}')
stage=$(tmux display -p -t 1 '#{pane_tty}')

# Actors

koala () {
    local geometry="0 0 37 11 bottom-left"
    draw "$geometry" -f koala <<<"$1" > $stage
    #say espeak "$1"
}

cow () {
    local geometry="37 0 43 11 bottom-left"
    draw "$geometry" <<<"$1" > $stage
    #say mplayer "$1"
}

# Let the play begin!

koala; cow

koala "Hello dude! What's up?"

sleep 1

cow "I'm great! Thanks for asking. How are you? Any computer headaches?"

sleep 2

koala; cow

koala "Well, I can't figure out what this command does..."

echo "$(tput bold)$(tput setaf 4)ls -ltr$(tput sgr0)" > $screen
sleep 1
echo "$(ls -ltr)" > $screen

sleep 1

cow "Well, it..."

sleep 2

the-end
