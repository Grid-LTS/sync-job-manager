#!/bin/bash

# taken from https://stackoverflow.com/questions/3685970/check-if-a-bash-array-contains-a-value
containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

check_client_available () {
  bin=$1
  $bin --version &> /dev/null || $bin -version &> /dev/null
  if [ $? != 0 ]; then
    echo "The client ${bin} is not available on your system. Abort"
    return 1
  fi
}
