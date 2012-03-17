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
  local length
  local section="0"
  while read -r length; do
    section=$(($section + 1))
    if [ "${1}" = "-m" ]; then
      serenity.tokens.deserializeSection "$length" "$section:"
    else
      serenity.tokens.deserializeSection "$length"
    fi
  done
  if [ "${1}" = "-m" ]; then
    serenity__currentTokens["sections"]="$section"
  fi
}

serenity.tokens.deserializeSection() {
  local key=""
  local tmp=""
  local i
  local length="${1}"
  local -r STATE_KEY=0
  local -r STATE_VALUE=1
  local state="$STATE_KEY"
  for i in $(seq 1 $(($length * 2))); do
    read -r tmp
    case "${state}" in
      "${STATE_KEY}")
        key="${tmp}"
        state="${STATE_VALUE}";;
      "${STATE_VALUE}")
        serenity__currentTokens["${2}""${key}"]="${tmp}"
        state="${STATE_KEY}";;
    esac
  done
}

serenity.tokens.serialize() {
  local key=""
  echo "${#serenity__currentTokens[@]}"
  for key in "${!serenity__currentTokens[@]}"; do
    echo "${key}"
    echo "${serenity__currentTokens[${key}]}"
  done
}

serenity.tokens.copyPrefix() {
  local dest=""
  local k
  [ -n "$2" ] && dest="$2:"
  for k in "${!serenity__currentTokens[@]}"; do
    if [ -n "$1" ]; then
      [[ "$k" =~ ^$1:(.+) ]] &&
      serenity.tokens.set "$dest${BASH_REMATCH[1]}" "${serenity__currentTokens["$k"]}"
    else
      ! [[ "$k" =~ ^[0-9]+:(.+) ]] &&
      serenity.tokens.set "$dest$k" "${serenity__currentTokens["$k"]}"
    fi
  done
}

serenity.tokens.get() {
  local prefix=""
  if [ "${1}" = "-m" ]; then
    prefix="${2}:"
    shift 2
  fi
  if serenity.tools.contains "${prefix}${1}" "${!serenity__currentTokens[@]}"; then
    echo "${serenity__currentTokens["${prefix}${1}"]}"
  elif serenity.tools.contains "${1}" "${!serenity_conf_tokenDefaults[@]}"; then
    echo "${serenity_conf_tokenDefaults["${1}"]}"
  else
    echo "${serenity_conf_tokenDefaults['default']}"
  fi
}

serenity.tokens.set() {
  serenity.debug.debug "Tokens: set ${1} to ${2}"
  serenity__currentTokens["${1}"]="${2}"
}
