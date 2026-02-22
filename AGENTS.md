# AGENTS - Sync Job Manager

## Overview
This repository contains Bash shell scripts that manage synchronization between client computers and a central server, supporting Git and Unison protocols. The project automates folder/project synchronization on distributed systems.

## Build, Lint, and Test Commands

### Running Tests
This project currently has **no automated tests**. Tests should be added as a new feature.

### Code Style Guidelines

#### Shell Script Style
- **Shebang**: Always start with `#!/bin/bash` for consistency
- **Indentation**: Use 2 spaces for indentation (no tabs)
- **Line Length**: Keep lines under 100 characters (long lines require wrapping)
- **Brackets**: Always use curly braces for multi-line conditionals
  ```bash
  # Good
  if [ ${#arr[@]} -gt 1 ]; then
      echo "Multiple values"
  fi

  # Avoid (multi-line without braces)
  if [ -f $file ]
  then
      echo "Invalid"
  fi
  ```

#### Variable Naming
- Use underscores for multi-word variables: `local_path`, `ssh_login`, `is_win`
- State variables start with verbs: `mode=unison`, `force=0`
- Use clear, descriptive names, never abbreviate unnecessarily

#### Function Naming
- Use verb-first naming: `check_client_available()`, `find_repo_name()`
- Use snake_case for function names
- Functions should be named consistently with prompts: validate-client-available, verify-file-exists

#### Error Handling
- Always use explicit exit codes (0 for success, 1 for failure)
- Check command success with conditional statements
- Provide meaningful error messages in plain English
  ```bash
  # Example error handling pattern
  if [ $? -ne 0 ]; then
      echo "ERROR: Local branch $branch does not have a remote ref"
      continue
  fi
  ```
- Use `&> /dev/null` for quiet command execution when checking availability
- Print status updates to stdout (>&1)

#### String Manipulation
- Use arrays for multiple values: `IFS=',' read -r -a envs <<< "$str"`
- Use parameter expansion: `${var#pattern}`, `${var%pattern}`, `${var/old/new}`
- Use `sed` for pattern replacement and trimming whitespace
- Always quote variables: `"${path}"`, `"${url}"`

#### File Operations
- Always quote file paths to prevent glob expansion: `"$file"`, `"$conffile"`
- Use `find -L` for symlink resolution
- Use `print0` and `read -d ''` for null-delimited input to handle filenames with spaces
- Use `&> /dev/null` for error redirection when checking existence

#### Process Substitution
- Use `< <(command)` for process substitution when you need to use command output as input
- Example: `done < <(git for-each-ref --format='...' refs/heads/)`
- Process substitution must be last command in a while loop

#### IFS (Field Separator) Handling
- Save IFS before use: `IFS_OLD=$IFS`, `IFS=','`
- Restore IFS after use: `IFS=$IFS_OLD`
- Don't define IFS globally without reverting

#### Bash Specifics
- Always escape special characters in double quotes: `\` before `$`, `` ` `"`, `\`
- Use `$(...)` for command substitution (preferred over backticks)
- Use arithmetic comparison: `[ $count -gt 10 ]`, not `> 10` in brackets
- Use `[ ]` for single-line conditionals, `[[ ]]` for multi-line with regex matching
- Avoid `[[ ]]` unless needed for regex comparison

#### Truepath and Directory Operations
- Use `cd -P` for directory resolution (resolves symlinks)
- Use `dirname "$SOURCE"` for parent directory
- Use `basename "$path"` for filename
- Use `pwd` for current working directory

#### Comments and Documentation
- Keep comments concise and immediately adjacent to the code they document
- For multi-line blocks, put comments at the beginning describing the purpose
- Keep code self-documenting; use descriptive variable and function names


#### Config File Parsing
- Comments start with `#`
- Empty lines are ignored
- Blocks start with `[mode_name]` to mark configuration sections
- Environment blocks can be restricted: `env=home,playground`
- Parse line by line; ignore comments by checking first character

#### Processing Files with stdin for SSH
- When using `while read` for config files, need different file descriptor: `10< $conffile`
- This prevents SSH from reading from parent process stdin
- Symlink resolution: Loop `while [-h "$SOURCE"]` until path is no longer a symlink

#### Unison Profile Management
- Template profiles are in `unison-templates/` directory
- Concrete profiles generated in `~/.unison/` directory
- Add URL patterns: `s|@local_path@|${local_path}|g`
- Handle spaces in paths: `${base// /-}`

#### Windows Compatibility
- Detect Windows with `is_win=$([ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ] && echo "1")`
- Convert paths with `cygpath -w "$path"`
- Handle backslashes appropriately

#### SSH Integration
- Construct `ssh_user@ssh_host` format
- Use `ssh_login="${ssh_user}@${ssh_host}"`
- Use `ssh://$ssh_login/$path` for URL prefixing
- Handle SSH in URLs: Separate prefix and path components

#### Status and Debugging
- Print status updates mid-processing: `"Config block only applies to environments ${envs[@]}"`
- Use environment variable to filter restrictions: `$BACKUP_SYNC_ENV`
- Indicate progress: `"Checking for template at $template_file_path"`

### Testing New Features
When adding new features:
1. Verify the script can handle filenames with spaces and special characters
2. Test with empty files, commented files
3. Test error conditions (missing files, invalid paths)
4. Verify Windows/Linux cross-platform behavior
5. Update configuration examples if parameters change

### Git and Commit Guidelines
When committing changes to existing code:
- Add self-explanatory commit messages
- Follow descriptive messaging style
- Bypass linting for temporary debugging commits
- For bug fixes or new features, ensure tests exist and pass


### Environment Variables
- `SYNC_CONFIG_HOME`: Override default config directory (default: script directory)
- `BACKUP_SYNC_ENV`: Current active sync environment (required for authentication)
- `confdir`: Default path to configuration files (default: `~/.sync-conf`)