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

serenity.tokens.deserialize() {
  local key=""
  local tmp=""
  local -r STATE_KEY=0
  local -r STATE_VALUE=1
  local state="$STATE_KEY"
  while read -r tmp; do
    case "${state}" in
      "${STATE_KEY}")
        key="${tmp}"
        state="${STATE_VALUE}";;
      "${STATE_VALUE}")
        serenity__currentTokens["${key}"]="${tmp}"
        state="${STATE_KEY}";;
    esac
  done
}

serenity.tokens.serialize() {
  local key=""
  for key in "${!serenity__currentTokens[@]}"; do
    serenity.tokens.addToStream "${key}" "${serenity__currentTokens[${key}]}"
  done
}

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
    echo "${serenity__currentTokens["${1}"]}"
  elif ! $noDefault; then
    if serenity.tools.contains "${1%*::}" "${!serenity_conf_tokenDefaults[@]}"; then
      echo "${serenity_conf_tokenDefaults["${1%*::}"]}"
    else
      echo "${serenity_conf_tokenDefaults['default']}"
    fi
  fi
}

serenity.tokens.set() {
  serenity.debug.debug "Tokens: set ${1} to ${2}"
  serenity__currentTokens["${1}"]="${2}"
}


serenity.tokens.isSet() {
  serenity.tools.contains "${1}" "${!serenity__currentTokens[@]}"
}

serenity.tokens.filter.copyPrefix() {
  local -A serenity__currentTokens=()
  serenity.tokens.deserialize

  local orig="$1"
  local dest="$2"

  [ -n "$orig" ] && orig="$orig::"
  [ -n "$dest" ] && dest="$dest::"

  local key
  for key in "${!serenity__currentTokens[@]}"; do
    if [[ (-n "$orig" && "$key" == "$orig"*) || (-z "$orig" && "$key" != *::*) ]]; then
      serenity.tokens.set "$dest${key#$orig}" "${serenity__currentTokens["$key"]}"
    fi
  done
  serenity.tokens.serialize
}

serenity.tokens.addToStream() {
  echo "$1"
  echo "$2"
}