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

serenity.tools.urlEncode() {
  local arg="$1"
  while [[ "$arg" =~ ^([0-9a-zA-Z/:_\.\-]*)([^0-9a-zA-Z/:_\.\-])(.*) ]]; do
    echo -n "${BASH_REMATCH[1]}"
    printf "%%%X" "'${BASH_REMATCH[2]}'"
    arg="${BASH_REMATCH[3]}"
  done
  # the remaining part
  echo -n "$arg"
}

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

