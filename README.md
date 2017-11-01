## Sync Job Manager

### Description
This script automates the task of syncing folders and projects (databases) on client computers with a central server. It builds on other software for data synchronization between distributed systems.
At the moment support for Git & Unison is implemented, but other protocols like rsync are planned for the future.
In case of Git **all** branches in for those projects, which are stated in the *.conf files, will be synced with the server.  

### Usage
for pulling changes from the server
```
./server-sync.sh pull $conf-file
```
for pushing to the server
```
./server-sync.sh push $conf-file
```
for setting the config (name + email address only possible for git repos)
```
./server-sync.sh set-conf
```

### Configuration
- Git repositories have to be set up and wired by yourself for each client and the server
- *.conf-files: the path to the local Git project and the remote url of the server repo have to be provided in conf-files
- *.conf files should be in the home directory under ~/.sync-conf or can be provided as an argument to the call
- best would be to set up an easy authentification method with the server, like a key-based method, in order to avoid prompts when running the script
- for setting the git config for a repo, you need to provide the name + email address next to the repository path


### Requirements
Can only be run from a Bash, e.g. MacOs or Linux distribution with git and unison installed (and a transfer protocol as ssh on client and server)

### Currently planned
- lock files
- specify if only push, only pull or both modes are applied to each repo
- gui for convenient setup of conf files
- error report in case of conflicts or failed checkouts
At the moment the script is simple and not laid out to sync in collaborative projects. E.g. in case of git, when pushing the server branches are expected to be fast-fowarded. The same applies to pulling.
Merges cannot be handled. In the future this should be possible.
