#!/bin/bash

# set global parameters
IFS=' '

mode="git"
cwd=$(pwd)
force=0

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

while [[ -n $1 ]]; do
	case "$1" in
			pull) action=pull 	;;
			push) action=push	;;
			set-conf | set-config) $DIR/src/set_repo_config
						exit 0;;
			-f | --force) force=1;;
			--file) shift file=$1;;
			*)	if [ -f "$1" ]; then
					file=$1
				else
					echo "Only push, pull, set-conf are allowed actions"
					exit 1
				fi 
				;;
	esac
	shift
done

# collect all conf-files in an array
files=()
if [ -n "$2" ]; then
	files+=("$2")
else
	i=0
	confdir="${HOME}/.sync-conf"
	while read -r -d ''; do
		files+=("$REPLY")
	done < <(find $confdir -type f -name '*.conf' -print0)
fi


if [ ${#files[@]} -ne 0 ]; then
	for conffile in ${files[@]}; do
		if [ -f $conffile ]; then
			while read source url; do
			source=${source// } # remove spaces
			# ignore comments or empty lines
			if [[ "$source" == \#* || "$source" == "" ]]; then
				continue
			fi
			
			if [[ -z "$url" ]]; then
				case "$source" in
					\[git\]) mode="git"
						;;
					\[unison\]) mode="unison"
						;;
				esac
					continue
				fi
		 
				case $mode in
					git) $DIR/src/sync_git_repo $action $force $source $url >&1 ;;
					*) continue;;
				esac		
			done < $conffile
		fi
done
fi


