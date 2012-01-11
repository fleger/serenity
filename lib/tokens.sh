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
    echo "${key}"
    echo "${serenity__currentTokens[${key}]}"
  done
}

serenity.tokens.get() {
  if serenity.tools.contains "${1}" "${!serenity__currentTokens[@]}"; then
    echo "${serenity__currentTokens["${1}"]}"
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
