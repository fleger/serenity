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
