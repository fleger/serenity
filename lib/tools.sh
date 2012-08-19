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

serenity.tools.contains() {
  local item
  local match="$1"
  shift

  for item; do
    [ "x$item" = "x$match" ] &&
    return 0
  done
  return 1
}

serenity.tools.characters() {
  local arg="$1"
  local i=-1
  while (( ++i < ${#arg} )); do
    echo "${arg:$i:1}"
  done
}

serenity.tools.isFunction() {
  [[ "$(type -t "$1")" = "function" ]]
}

serenity.tools.isExecutable() {
  serenity.tools.isFunction "$1" || which "$1" &> /dev/null
}

# serenity.tools.listFunctions PATTERN
# List functions matching PATTERN
# If present, matched subpatterns surrounded by parenthesis
# are listed instead of the function names.
serenity.tools.listFunctions() {
  local f
  for f in $(compgen -A function); do
    [[ "$f" =~ $1 ]] && {
      if [[ ${#BASH_REMATCH[@]} -gt 1 ]]; then
        echo "${BASH_REMATCH[*]:1}"
      else
        echo "$f"
      fi
    }
  done
}

serenity.tools.localUnset() {
  local v
  for v; do
    unset -v "$v"
  done
}

serenity.tools.lockFile() {
  local opt
  local OPTARG
  local -i OPTIND=1
  local lockType="-x"
  while getopts s opt; do
    case "$opt" in
      s) lockType="-s";;
    esac
  done
  shift $((${OPTIND} - 1))

  local lockFile="$1"
  local -i returnCode="0"

  shift
  exec 8>>"$lockFile"
  flock "$lockType" 8
  "$@" || returnCode=1
  exec 8>&-
  return $returnCode
}
