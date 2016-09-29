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

# takes the path to the repo and returns the last two directories
get_repo_name(){
	base=$(basename $1)
	dir=$(basename $(dirname $1))
	name="${dir}/${base}"
	echo $name
	return
}

sync_git_repo() {
	start=$(pwd)
	path=$2
	action=$1
	reponame=$(get_repo_name $path)
	echo $reponame
	path="${path/#\~/$HOME}"
	cd $path
	echo "Fetch changes from the server"
	git fetch
	if [ "$action" == "push" ]; then
		git fetch > /dev/null
		git push --all
		echo -e "\n"
	fi
	if [ "$action" == "pull" ]; then
		while read branch; do
			echo $branch
			git checkout $branch >> /dev/null 
			git pull
		done < <(git for-each-ref --format='%(refname:short)' refs/heads/) 
	fi
	echo -e "\n"
	cd $start
}

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
					git) sync_git_repo $action $source $url;;
					*) continue;;
				esac		
			done < $conffile
		fi
done
fi


