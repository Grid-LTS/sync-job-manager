## Sync Job Manager

### Description
This script automates the task of syncing folders and projects (databases) on client computers with a central server. It builds on other software for data synchronization between distributed systems. 
At the moment only Git is implemented, but other protocols like unison and rsync are planned as well.
In case of Git **all** branches in all projects, stated in the *.conf files, will be synced with the server.  

### Usage
for pulling changes from the server
```
./server-sync.sh pull $conf-file
```
for pushing to the server
```
./server-sync.sh push $conf-file
```

### Configuration
- Git repositories have to be set up and wired by yourself for each client and the server
- *.conf-files: the path to the local Git project and the remote url of the server repo have to be provided in conf-files
- *.conf files should be in the home directory under ~/.sync-conf or can be provided as an argument to the call
- best would be to set up an easy authentification method with the server, like a key-based method, in order to avoid prompts when running the script

### Requirements
Can only be run from a Bash, e.g. MacOs or Linux distribution with git installed (and a transfer protocoll as ssh on client and server)

### Currently planned
- lock files
- gui for convenient setup of conf files
- only commits are synced, but also unstaged and staged changes should be synced  
At the moment the script is simple and not laid out to sync in collaborative projects. E.g. in case of git, when pushing the server branches are expected to be fast-fowarded. The same applies to pulling. 
Merges cannot be handled. In the future this should be possible.
   
