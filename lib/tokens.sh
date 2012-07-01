#    serenity - An automated episode renamer.
#    Copyright (C) 2010-2011  Florian Léger
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Tokens

# ----------------------
# Context core functions
# ----------------------
serenity.tokens.execute() {
  local -a __inits=()
  local -a __initsLengths=()
  local -a __exits=()
  local -a __exitsLengths=()
  local -a __functions=()
  local -a __functionsLengths=()

  "$@"

  serenity.tokens.__run
}

serenity.tokens.add() {
  local -r FUNCTION=0
  local -r INIT=1
  local -r EXIT=2
  
  local opt
  local OPTARG
  local OPTIND=1
  local mode="$FUNCTION"
  while getopts ie opt; do
    case "$opt" in
      i) mode="$INIT";;
      e) mode="$EXIT";;
    esac
  done
  shift $((${OPTIND} - 1))

  if [ $# -gt 0 ]; then
    case "$mode" in
      "$FUNCTION")
        __functionsLengths+=($#)
        __functions+=("$@");;
      "$INIT")
        __initsLengths+=($#)
        __inits+=("$@");;
      "$EXIT")
        __exitsLengths+=($#)
        __exits+=("$@");;
    esac
  fi
}

serenity.tokens.__run() {
  local -i offset
  local -i length
  local key
  local tokens_phase=""
  local retval
  
  offset=0
  tokens_phase="init"
  local -A tokens_init=()
  for length in "${__initsLengths[@]}"; do
    "${__inits[@]:$offset:length}"
    retval=$?
    [[ $retval == 0 ]] || return $retval
    offset=$(( $offset + $length ))
  done

  local -A tokens_current=()
  for key in "${!tokens_init[@]}"; do
    tokens_current["$key"]="${tokens_init["$key"]}"
  done
  serenity.tools.localUnset tokens_init
  
  offset=0
  tokens_phase="body"
  for length in "${__functionsLengths[@]}"; do
    "${__functions[@]:$offset:length}"
    retval=$?
    [[ $retval == 0 ]] || return $retval
    offset=$(( $offset + $length ))
  done

  local -A tokens_exit=()
  for key in "${!tokens_current[@]}"; do
    tokens_exit["$key"]="${tokens_current["$key"]}"
  done
  serenity.tools.localUnset tokens_current

  offset=0
  tokens_phase="exit"
  for length in "${__exitsLengths[@]}"; do
    "${__exits[@]:$offset:length}"
    retval=$?
    [[ $retval == 0 ]] || return $retval
    offset=$(( $offset + $length ))
  done
}

# ----------------------------------
# Basic token manipulation functions
# ----------------------------------
serenity.tokens.get() {
  local -r FUNCTION=0
  local -r INIT=1
  local -r EXIT=2

  local opt
  local OPTARG
  local OPTIND=1
  local mode="$FUNCTION"
  local noDefault=false
  while getopts ien opt; do
    case "$opt" in
      i) mode="$INIT";;
      e) mode="$EXIT";;
      n) noDefault=true;;
    esac
  done
  shift $((${OPTIND} - 1))

  case "$mode" in
    "$FUNCTION")
      serenity.tokens.isSet "${1}" && echo "${tokens_current["${1}"]}" && return 0;;
    "$INIT")
      serenity.tokens.isSet -i "${1}" && echo "${tokens_init["${1}"]}" && return 0;;
    "$EXIT")
      serenity.tokens.isSet -e "${1}" && echo "${tokens_exit["${1}"]}" && return 0;;
  esac
  if ! $noDefault; then
    if serenity.tools.contains "${1%*::}" "${!serenity_conf_tokenDefaults[@]}"; then
      echo "${serenity_conf_tokenDefaults["${1%*::}"]}"
    else
      echo "${serenity_conf_tokenDefaults['default']}"
    fi
  fi
}
# serenity.tokens.set TOKEN_TYPE TOKEN_VALUE
#
# Set the value of TOKEN_TYPE to TOKEN_VALUE.
#
# Closure: serenity.tokens.execute
serenity.tokens.set() {
  local -r FUNCTION=0
  local -r INIT=1
  local -r EXIT=2

  local opt
  local OPTARG
  local OPTIND=1
  local mode="$FUNCTION"
  while getopts ien opt; do
    case "$opt" in
      i) mode="$INIT";;
      e) mode="$EXIT";;
    esac
  done
  shift $((${OPTIND} - 1))

  case "$mode" in
    "$FUNCTION")
      tokens_current["${1}"]="${2}";;
    "$INIT")
      tokens_init["${1}"]="${2}";;
    "$EXIT")
      tokens_exit["${1}"]="${2}";;
  esac
  serenity.debug.debug "Tokens: set $1 to $2"
}

# serenity.tokens.isSet TOKEN_TYPE
#
# Test if TOKEN_TYPE is set in current_tokens.
#
# Closure: serenity.tokens.execute
serenity.tokens.isSet() {
  local -r FUNCTION=0
  local -r INIT=1
  local -r EXIT=2

  local opt
  local OPTARG
  local OPTIND=1
  local mode="$FUNCTION"
  while getopts ien opt; do
    case "$opt" in
      i) mode="$INIT";;
      e) mode="$EXIT";;
    esac
  done
  shift $((${OPTIND} - 1))

  case "$mode" in
    "$FUNCTION")
      serenity.tools.contains "${1}" "${!tokens_current[@]}";;
    "$INIT")
      serenity.tools.contains "${1}" "${!tokens_init[@]}";;
    "$EXIT")
      serenity.tools.contains "${1}" "${!tokens_exit[@]}";;
  esac
}

serenity.tokens.remove() {
  local -r FUNCTION=0
  local -r INIT=1
  local -r EXIT=2

  local opt
  local OPTARG
  local OPTIND=1
  local mode="$FUNCTION"
  while getopts ien opt; do
    case "$opt" in
      i) mode="$INIT";;
      e) mode="$EXIT";;
    esac
  done
  shift $((${OPTIND} - 1))

  case "$mode" in
    "$FUNCTION")
      unset tokens_current["$1"];;
    "$INIT")
      unset tokens_init["$1"];;
    "$EXIT")
      unset tokens_exit["$1"];;
  esac

  serenity.debug.debug "Tokens: removed $1"
}

# ---------------
# Prefix handling
# ---------------

# serenity.tokens.copyPrefix SOURCE DEST
#
# Copy the value of the token types prefixed by SOURCE to token types prefixed by DEST.
#
# Closure: serenity.tokens.execute
serenity.tokens.copyPrefix() {
  local orig="$1"
  local dest="$2"

  [ -n "$orig" ] && orig="$orig::"
  [ -n "$dest" ] && dest="$dest::"

  local key
  for key in "${!tokens_current[@]}"; do
    if [[ (-n "$orig" && "$key" == "$orig"*) || (-z "$orig" && "$key" != *::*) ]]; then
      serenity.tokens.set "$dest${key#$orig}" "${tokens_current["$key"]}"
    fi
  done
}

serenity.tokens.deletePrefix() {
  local prefix="$1"
  [ -n "$prefix" ] && prefix="$prefix::"

  local key
  for key in "${!tokens_current[@]}"; do
    if [[ (-n "$prefix" && "$key" == "$prefix"*) || (-z "$prefix" && "$key" != *::*) ]]; then
      serenity.tokens.remove "$key"
    fi
  done
}

serenity.tokens.movePrefix() {
  serenity.tokens.copyPrefix "$1" "$2"
  serenity.tokens.deletePrefix "$1"
}

# ---------------------------------
# Nested context convenience helper
# ---------------------------------
serenity.tokens.nestedExecute() {
  serenity.tokens.execute serenity.tokens.__nestedExecution "$@"
}

serenity.tokens.__nestedExecution() {
  serenity.tokens.add -i serenity.tokens.phaseAwareMerge
  "$@"
  serenity.tokens.add -e serenity.tokens.phaseAwareMerge
}

serenity.tokens.phaseAwareMerge() {
  local k
  serenity.debug.debug "Tokens.phaseAwareMerge $tokens_phase"
  case "$tokens_phase" in
    "init")
      for k in "${!tokens_current[@]}"; do
        serenity.tokens.set -i "$k" "${tokens_current["$k"]}"
      done;;
    "exit")
      for k in "${!tokens_exit[@]}"; do
        serenity.tokens.set "$k" "${tokens_exit["$k"]}"
      done;;
    *)
      return 1;;
  esac
}


# serenity.tokens.copyCommon DEST SOURCE...
#
# Copy all the tokens with the same value across all the SOURCEs into DEST
#
# Closure: serenity.tokens.execute, serenity.main
serenity.tokens.copyCommon() {
  local -A tokenValues=()
  local -a badTokens=()
  local dest="$1"
  [ -n "$dest" ] && dest="$dest::"
  shift
  local key
  for key in "${!tokens_current[@]}"; do
    {
      [[ "$key" == *::* ]] &&
      serenity.tools.contains "${key%%::*}" "${@}"
    } || {
      [[ "$key" != *::* ]] &&
      serenity.tools.contains "" "${@}"
    } && {
      if ! serenity.tools.contains "${key#*::}" "${badTokens[@]}"; then
        if serenity.tools.contains "${key#*::}" "${!tokenValues[@]}"; then
          if [[ "$(serenity.tokens.get "$key")" != "${tokenValues["${key#*::}"]}" ]]; then
            badTokens+=("${key#*::}")
          fi
        else
          tokenValues["${key#*::}"]="$(serenity.tokens.get "$key")"
        fi
      fi
    }
  done
  for key in "${!tokenValues[@]}"; do
    serenity.tools.contains "${key}" "${badTokens[@]}" ||
    serenity.tokens.set "$dest$key" "${tokenValues["$key"]}"
  done
}
