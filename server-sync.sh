#!/bin/bash

mode="git"
cwd=$(pwd)
action=$1
file=$2

case "$action" in
			pull) 	;;
			push)	;;
			*) echo "Only push or pull are allowed actions"
			exit 1;;
esac

#collect all conf-files in an array
files=()
if [ -n "$2" ]; then
	files+=("$2")
else
	i=0
	confdir="${HOME}/.filesync"
	while read -r -d ''; do
		files+=("$REPLY")
	done < <(find $confdir -type f -name '*.conf' -print0)
fi



sync_git_repo() {
	start=$(pwd)
	path=$1
	path="${path/#\~/$HOME}"
	cd $path
	while read branch; do
		echo $branch
	done < <(git for-each-ref --format='%(refname:short)' refs/heads/) 
	cd $start
}

if [ ${#files[@]} -ne 0 ]; then
	for conffile in ${files[@]}; do
		if [ -f $conffile ]; then
			while read source url; do
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
					git) sync_git_repo $source $url;;
					*) continue;;
				esac		
			done < $conffile
		fi
done
fi
