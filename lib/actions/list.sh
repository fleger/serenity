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

# List modules

serenity.actions.list.help() {
cat << EOM
list [MODULE_TYPE]

  List modules of the given MODULE_TYPE. If MODULE_TYPE is ommited, list the available module types.
EOM
}

serenity.actions.list.run() {
  if [[ $# -eq 0 ]]; then
    local i
    for i in "${!serenity_APIs[@]}"; do
      echo "$i"
    done
  else
    if ! serenity.tools.contains "$1" "${!serenity_APIs[@]}"; then
      serenity.crash "$1 is not a valid module type"
    fi
    serenity.tools.listFunctions "${serenity_APIs["$1"]}"
  fi
}
