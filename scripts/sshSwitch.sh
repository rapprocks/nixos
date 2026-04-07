#!/usr/bin/env bash

ssh -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedKeyTypes=+ssh-rsa -o KexAlgorithms=diffie-hellman-group14-sha1 -o IdentitiesOnly=yes -i $HOME/.ssh/switchkey admin@"$1"
