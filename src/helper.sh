#!/bin/bash

# taken from https://stackoverflow.com/questions/3685970/check-if-a-bash-array-contains-a-value
containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}
