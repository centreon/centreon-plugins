#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# trim(): prints the first argument trimmed
function trim() {
  local str="$1"
  echo "$str" | xargs
}

# Display an information with green INFO tag
function info() {
  echo -e "${GREEN}INFO${NC}: $*">&2
}

# Display an error message with red ERROR tag and increment errors counter if defined
function error() {
  echo -e "${RED}ERROR${NC}: $*">&2
  [[ -n "$errors" && "$errors" =~ ^[[:digit:]]+$ ]] && $((errors++))
}

# Display an error message with red FATAL tag and exits immediately
function fatal() {
  echo -e "${RED}FATAL${NC}: $*">&2
  exit 1
}

# parse_modes(command_line arg1 arg2 --list-mode): 
# Arguments: command and arguments of a list-mode command
# Output: declaration of an array variable named modes with the list of modes. Result has to be loaded using eval.
function parse_modes() {
  local IFS=$'\n'
  [[ $DEBUG ]] && set -x
  local MODES_OUTPUT=( $(perl $* 2>/dev/null ) )
  [[ $DEBUG ]] && set +x
  
  declare -a modes
  # Remove all lines above "Modes Available:"
  [[ $DEBUG ]] && declare -p MODES_OUTPUT
  
  local in_modes=
  local line
  for line in "${MODES_OUTPUT[@]}" ; do
    if [[ "$line" == 'Modes Available:' ]] ; then
      in_modes=1
      continue
    fi
    [[ -z "$in_modes" ]] && continue
    # add the current mode to the list
    modes+=($(trim $line))
  done
  
  [[ $DEBUG ]] && declare -p modes >&2
  declare -p modes
}

# parse_threshold_options_from_help(command_line arg1 arg2 --help): 
# Arguments: command and arguments of a help command
# Output: declaration of an array variable named threshold_options with the list of options that are specific to the mode. Result has to be loaded using eval.
function parse_threshold_options_from_help() {
  local IFS=$'\n'
  [[ $DEBUG ]] && set -x
  local HELP_OUTPUT=( $(perl $* 2>/dev/null ) )
  [[ $DEBUG ]] && set +x
  
  declare -a threshold_options
  # Remove all lines above "Modes Available:"
  
  local in_mode_help=
  local line
  for line in "${HELP_OUTPUT[@]}" ; do
    if [[ "$line" == 'Mode:' ]] ; then
      in_mode_help=1
      continue
    fi
    [[ -z "$in_mode_help" ]] && continue
    [[ "$line" =~ --(warning|critical)-\* ]] && fatal "Not parsing --warning-*/--critical-* thresholds"
    [[ "$line" =~ ^[[:space:]]*--[a-z0-9-]+$ ]] || continue
    threshold_options+=($(trim $line))
  done
  
  [[ $DEBUG ]] && declare -p threshold_options >&2
  declare -p threshold_options
}
