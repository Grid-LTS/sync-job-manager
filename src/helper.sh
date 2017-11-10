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


# url may or may not contain the ssh login
# in the latter case prefix it to the url
prefix_ssh_login () {
  part=$(awk -F "\/\/" '{print $2}' <<< "$url" )
  if [[ $part == *"@"* ]]; then
    prefix=$(awk -F "\/\/" '{print $1}' <<< "$url")
    prefix=${prefix%ssh:}
    url=$(awk -F "\/\/" '{print $3}' <<< "$url")
    url=${url// }
    url="${prefix}/${url}"
    ssh_login=$part
    return 0
  fi
  #no ssh  login given in path
  return 1
}
