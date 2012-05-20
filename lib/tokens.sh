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

# serenity.tokens.execute [OPTION].. FUNCTION [ARG]...
#
# Deserialize the tokens from STDIN, execute FUNCTION with ARGs,
# serialize the tokens to STDOUT.
#
# Options:
#   -S    Do not perform token serialization after calling FUNCTION
#   -D    Do not perform token deserialization before calling FUNCTION
#
# Upvalues:
#   tokens_current    Associative array containing the tokens
serenity.tokens.execute() {
  # Options
  local _tokens_opt_serialize=true
  local _tokens_opt_deserialize=true

  # Parse commandline
  local opt
  local OPTARG
  local OPTIND=1
  while getopts 'SD' opt; do
    case "$opt" in
      S) _tokens_opt_serialize=false;;
      D) _tokens_opt_deserialize=false;;
    esac
  done
  shift $((${OPTIND} - 1))

  unset opt
  unset OPTARG
  unset OPTIND

  local -A tokens_current=()
  "${_tokens_opt_deserialize}" &&
  serenity.tokens.deserialize

  "$@" && {
    "${_tokens_opt_serialize}" &&
    serenity.tokens.serialize
    return 0
  }
}

# serenity.tokens.deserialize
#
# Deserialize the tokens from STDIN into tokens_current.
serenity.tokens.deserialize() {
  local key=""
  local tmp=""
  local -r STATE_KEY=0
  local -r STATE_VALUE=1
  local state="$STATE_KEY"
  while IFS= read -r tmp; do
    case "${state}" in
      "${STATE_KEY}")
        key="${tmp}"
        state="${STATE_VALUE}";;
      "${STATE_VALUE}")
        tokens_current["${key}"]="${tmp}"
        state="${STATE_KEY}";;
    esac
  done
}

# serenity.tokens.serialize
#
# Serialize the tokens from tokens_current to STDOUT.
serenity.tokens.serialize() {
  local key=""
  for key in "${!tokens_current[@]}"; do
    serenity.tokens.addToStream "${key}" "${tokens_current[${key}]}"
  done
}

# serenity.tokens.get [OPTION]... TOKEN_TYPE
#
# Get the value of TOKEN_TYPE in tokens_current.
# If the value is not set, then TOKEN_TYPE's default value
# defined in serenity_conf_tokenDefaults is returned.
#
# Options:
#   -n    Do not perform default value look up
#
# Closures: serenity.tokens.execute, serenity.main
serenity.tokens.get() {
  local opt
  local OPTARG
  local OPTIND=1
  local noDefault=false
  while getopts n opt; do
    case "$opt" in
      n) noDefault=true;;
    esac
  done
  shift $((${OPTIND} - 1))

  if serenity.tokens.isSet "${1}"; then
    echo "${tokens_current["${1}"]}"
  elif ! $noDefault; then
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
  serenity.debug.debug "Tokens: set ${1} to ${2}"
  tokens_current["${1}"]="${2}"
}

# serenity.tokens.isSet TOKEN_TYPE
#
# Test if TOKEN_TYPE is set in current_tokens.
#
# Closure: serenity.tokens.execute
serenity.tokens.isSet() {
  serenity.tools.contains "${1}" "${!tokens_current[@]}"
}

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

# serenity.tokens.addToStream TOKEN_TYPE TOKEN_VALUE
#
# Serialize TOKEN_TYPE and TOKEN_VALUE to STDOUT.
serenity.tokens.addToStream() {
  echo "$1"
  echo "$2"
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