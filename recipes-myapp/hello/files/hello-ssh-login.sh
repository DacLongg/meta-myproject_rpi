#!/bin/sh

if [ -n "$SSH_CONNECTION" ] && [ -x /usr/bin/hello ]; then
    /usr/bin/hello --ssh-login
fi
