#!/bin/bash
#
# Takes an arbitrary set of parameters as commands that should be running.
# Writes them as "basename(cmd), cmd" to /var/cfengine/inputs/processes_run.csv
# and starts CFEngine.
# If you are passing arguments to a command, quote the command with the arguments,
# e.g. docker run myimage "/etc/init.d/apache2 start" "/usr/bin/mongod --noprealloc --smallfiles"
# The commands' basename should become a process in order to be detected by CFEngine.
# The commands will be run as root in a shell.

for cmd in "$@"
do
  file=${cmd%% *}
  base=${file##*/}
  echo "$base, $cmd" >> /var/cfengine/inputs/processes_run.csv
done

/var/cfengine/bin/cf-agent
/var/cfengine/bin/cf-execd -F
