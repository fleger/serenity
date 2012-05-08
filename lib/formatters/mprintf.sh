#    serenity - An automated episode renamer.
#    Copyright (C) 2010-2012  Florian Léger
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


# Token multi-printf formatting
serenity.formatters.mprintf.run() {
  local arg
  local format=""
  local -a fields=()
  local -r STATE_START=1
  local -r STATE_FORMAT=2
  local -r STATE_FIELD=3
  local -r STATE_EXIT_SUCCESS=98
  local -r STATE_ERROR=99
  local state="${STATE_START}"
  local errorCode=1
  for arg; do
    case "${state}" in
      "${STATE_START}")
        [ "${arg}" = "-f" ] &&
        state="${STATE_FORMAT}" ||
        state="${STATE_ERROR}";;

      "${STATE_FORMAT}")
        format="${arg}"
        state="${STATE_FIELD}";;

      "${STATE_FIELD}")
        [ "${arg}" = "-f" ] && {
          serenity.formatters.mprintf.printf "${format}" "${fields[@]}" && {
            errorCode=0
            state="${STATE_EXIT_SUCCESS}"
          } || {
            fields=()
            format=""
            state="${STATE_FORMAT}"
          }
        } || {
          fields+=("$arg")
        };;

      "${STATE_EXIT_SUCCESS}")
        break;;
        
      *)
        errorCode=2
        break;;
    esac
  done

  # Left over
  [ "${state}" = "${STATE_FIELD}" ] &&
  serenity.formatters.mprintf.printf "${format}" "${fields[@]}" &&
  errorCode=0

  return "$errorCode"
}

serenity.formatters.mprintf.printf() {
  local format="${1}"
  shift

  local -a fields=()
  local tokenType=""

  for tokenType; do
    serenity.tokens.isSet "${tokenType}" || [ -n "$(serenity.tokens.get "${tokenType}")" ] && {
      fields+=("$(serenity.tokens.get "${tokenType}")")
    } || {
      serenity.debug.debug "mprintf: [KO] ${format} $*"
      return 1
    }
  done

  serenity.debug.debug "mprintf: [OK] ${format} $*"
  printf "${format}" "${fields[@]}"
}
