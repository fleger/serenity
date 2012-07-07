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

# Show help text

serenity.actions.help.help() {
cat << EOM
help [MODULE_TYPE]...

  Show help about serenity modules.

  Arguments:

    MODULE_TYPE     show help for modules of MODULE_TYPE. Use the 'list' action to list the available
                    module types. [default: 'actions']
EOM
}

serenity.actions.help.run() {
  local -a apis=()
  local indentation=""

  if [[ $# -eq 0 ]]; then
    echo "Usage: ${serenity_env_executable} ACTION"
    echo
    apis+=("actions")
    indentation+="  "
  else
    apis+=("$@")
  fi
  
  local api
  local item
  local line
  local helpFunc

  for api in "${apis[@]}"; do
    if ! serenity.tools.contains "$api" "${!serenity_APIs[@]}"; then
      serenity.crash "$api is not a valid module type"
    fi

    echo "$indentation${api^*}:"
    echo
    indentation+="  "
    
    for item in $(serenity.tools.listFunctions "${serenity_APIs["$api"]}"); do
      helpFunc="$(printf ${serenity_APIs_help["$api"]} "$item")"
      if serenity.tools.isFunction "$helpFunc"; then
        "$helpFunc" | while IFS= read line; do
          echo "$indentation$line"
        done
        echo
        echo
      fi
    done

    indentation="${indentation%  }"
  done
}
