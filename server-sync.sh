#!/bin/bash

# set global parameters
IFS=' '

mode="unison"
cwd=$(pwd)
force=0
is_backup=0

export confdir="${HOME}/.sync-conf"

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
export DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
echo "Current directory ${DIR}"

# settings directory that contains global and client specific parameters (credentials, paths)
if [ -z "$SYNC_CONFIG_HOME" ]; then
  export SYNC_CONFIG_HOME=$DIR
fi

if [ "$(uname)" == "Darwin" ]; then
  is_win="0"
else
  is_win=$([ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ] && echo "1")
fi

if [[ $is_win == "1" ]]; then
  psh_script=$HOME/bin/unison-sync.ps1
  psh_script_force=$HOME/bin/unison-sync-force.ps1
  # will be regenerated
  if [ -f $psh_script ]; then
    rm $psh_script
  fi
  if [ -f $psh_script_force ]; then
    rm $psh_script_force
  fi
fi


# load global properties like host, ssh-login
if [ -f "$SYNC_CONFIG_HOME/server-sync.properties" ]; then
  . "$SYNC_CONFIG_HOME/server-sync.properties"
else
    #initialize variables
    export ssh_user=''
    export ssh_host=''
  
fi

if [ -f "$DIR/server-sync.properties" ]; then
    . "$DIR/server-sync.properties"
fi


. $DIR/src/helper.sh

while [[ -n $1 ]]; do
	case "$1" in
			pull) action=pull 	;;
			push) action=push	;;
			set-conf | set-config) action=save_settings
						                 ;;
			-f | --force) force=1;;
--file) shift
              file=$1;;
       --env) shift
              export BACKUP_SYNC_ENV=$1;;
       --backup | --backup-sync) is_backup=1;;
       -c | --client ) shift
               client=$1;;
			*)  echo "Only push, pull, set-conf are allowed actions"
					exit 1
				;;
	esac
	shift
done

if [ -z "$action" ]; then
  echo "No action parameter given."
  exit 1
fi

if [ -z "$force" ]; then
  force=0
fi

if [ -z "$BACKUP_SYNC_ENV" ]; then
  echo "Environment parameter \$BACKUP_SYNC_ENV is not set."
  BACKUP_SYNC_ENV=""
  exit 1
fi

echo "Use sync environment $BACKUP_SYNC_ENV"


if [ -n "$client" ]; then
  echo "Only syncing with ${client} client."
fi

if [ -z "$file" ]; then
  # no file specified as argument
  # collect all conf-files in an array
  files=()
  if [ -n "$2" ]; then
  	files+=("$2")
  else
  	i=0
  	while read -r -d ''; do
  		files+=("$REPLY")
  	done < <(find -L $confdir -maxdepth 1 -type f -name '*.conf' -print0)
  fi
else
  files=($file)
fi

if [ ${#files[@]} -ne 0 ]; then
  for conffile in ${files[@]}; do
    echo ""
    echo "Reading $(basename $conffile)"
		if [ -f $conffile ]; then
      # read conf files line by line and start client for each line
      # read needs to use a different descriptor for stdin because we will run a ssh command inside which also reads from stdin
      # see https://unix.stackexchange.com/questions/107800/using-while-loop-to-ssh-to-multiple-servers
      while read -u10 line || [ -n "$line" ];
        do
        sourcepath=$(echo "$line" | grep -o '".*"' | sed 's/"//g')
        if [ -z "$sourcepath" ]; then
          sourcepath="$( cut -d ' ' -f 1 <<< "$line" )"
          prepend=""
          rest=${line//"$sourcepath"/}
        else
          prepend="$(awk -F"\"" '{print $1}' <<< "$line")"
          rest=${line//"${prepend}\"$sourcepath\""/}
        fi
        source="${prepend}$sourcepath"
        url="$(awk '{print $1}' <<< "$rest")"
        # read rest of the line into the settings string
        settings=$(awk '{$1=""; print $0}' <<< "$rest")
        # remove leading white space, see https://stackoverflow.com/questions/369758/how-to-trim-whitespace-from-a-bash-variable
        settings="$(echo -e "${settings}" | sed -e 's/^[[:space:]]*//')"
        #remove trailing whitespace
        settings="$(echo -e "${settings}" | sed -e 's/[[:space:]]*$//')"
        # read config line by line
        # ignore comments or empty lines
        if [[ "$source" == \#* || "$source" == "" ]]; then
          continue
        fi
        if [[ -z "$url" ]]; then
          if [[ "$source" =~ \[([a-zA-Z0-9_]+)\] ]]; then
            block_is_valid=0
            sync_client="${BASH_REMATCH[1]}"
            echo "Sync client: $sync_client"
            case "$sync_client" in
              unison)
              [ $action == 'save_settings' ] &&  echo 'No settings can be saved for unison projects' && break
              check_client_available "unison"
              [ $? != 0 ] && break
              mode="unison"
              ;;
            *)  echo "The sync mode '${sync_client}' is not supported."
              break
              ;;
            esac
            if [ -n "$client" ] && [ "$mode" != "$client" ]; then
              echo "Syncing with ${mode} is ignored."
            fi  
    		    continue
    		  else
            source="${source//[\[\]$'\t\r\n']}"
            echo "$source" | grep -q 'env'
            is_env_restricted=$?
            if [ $is_env_restricted -eq 0 ] && [ -z "$BACKUP_SYNC_ENV" ]; then
              # conf file restricted to certain environments, but no environment
              # specified. skip
              block_is_valid=0
            fi
            if [ $is_env_restricted -eq 0 ] && [ -n "$BACKUP_SYNC_ENV" ]; then
              # check if given environment is part of the specified envs
              source="${source#env=}"
              IFS_OLD=$IFS
              # read environemnts into an array $envs
              IFS=','
              read -r -a envs <<< "$source"
              echo "Config block only applies to environments ${envs[@]}"
              IFS=$IFS_OLD
              # stop reading this config file if only valid for another environment
              if ! containsElement "$BACKUP_SYNC_ENV" "${envs[@]}"; then 
                block_is_valid=0
              else
                block_is_valid=1
              fi
            fi
            continue
          fi
        fi
        if [ $block_is_valid -eq 0 ]; then
          # skip this block as it is not valid for the given environment
          continue
        fi
        if [ -z "$mode" ]; then
          echo 'No syncing tool given. Ignore conffile'
          break;
        fi
        if [ -n "$client" ] && [ "$mode" != "$client" ]; then
          continue
        fi
        if [ "$action" == 'save_settings' ]; then
          execute="${mode}-settings"
          $DIR/src/$execute $source "$settings" >&1
        else
          # Check for backup mode or unison mode
          if [ "$is_backup" == "1" ]; then
            # Backup mode - use rsync locally
            execute="backup-sync"
            # Pass minimal args - ssh-login, server-path, settings not used
            $DIR/src/$execute $action $force "$source" "$is_win" >&1
          else
            # Unison mode - process normally with SSH
            ssh_login=""
            # check if ssh login information is given, if yes overwrite default values
            if [ -z "$ssh_login" ] && [ -n "$ssh_user" ] && [ -n "$ssh_user" ]; then
              ssh_login="${ssh_user}@${ssh_host}"
            fi
            if [ -z "$ssh_login" ]; then
              echo "No ssh login available for target $url"
              continue
            fi
            # sync with repos
            execute="${mode}-sync"
            $DIR/src/$execute $action $force $ssh_login "$source" "$url" "$settings" "$is_win" >&1
          fi
        fi
      done 10< $conffile
    fi
  done
fi
