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
help [MODULE_TYPE[.MODULE_NAME]]...

  Show help about serenity modules.

  Arguments:

    MODULE_TYPE     show help for modules of MODULE_TYPE. Use the 'list' action to list the available
                    module types. [default: 'actions']

    MODULE_NAME     show help for the module named MODULE_NAME of type MODULE_TYPE. Use the 'list MODULE_TYPE'
                    action to list the available modules for the given MODULE_TYPE.
EOM
}

serenity.actions.help.run() {
  local -a args=()
  local indentation=""

  if [[ $# -eq 0 ]]; then
    echo "Usage: ${serenity_env_executable} ACTION"
    echo
    args+=("actions")
    indentation+="  "
  else
    args+=("$@")
  fi

  local -A sections=()
  local moduleType
  local moduleName
  local item

  # Build sorted list
  for item in "${args[@]}"; do
    case "$item" in
      *.*) # Specific module
        moduleType="${item%.*}"
        moduleName="${item##*.}"
        if ! serenity.tools.contains "${!sections["$moduleType"]}" || [[ -n "${sections["$moduleType"]}" ]]; then
          sections["$moduleType"]+=" $moduleName"
        fi
        ;;
      *) # Whole module type
        sections["$item"]=""
        ;;
    esac
  done

  for moduleType in "${!sections[@]}"; do
    serenity.actions.help.printModuleTypeHelp "$moduleType" ${sections["$moduleType"]}
  done
}

serenity.actions.help.printModuleTypeHelp() {
  local -a modules=()
  local moduleType
  local moduleName
  moduleType="$1"
  shift
  if ! serenity.tools.contains "$moduleType" "${!serenity_APIs[@]}"; then
    serenity.crash "$moduleType is not a valid module type"
  fi

  echo "$indentation${moduleType^*}:"
  echo
  indentation+="  "

  if [[ "$#" -eq 0 ]]; then
    readarray -t modules < <(serenity.tools.listFunctions "${serenity_APIs["$moduleType"]}")
  else
    modules=("$@")
  fi

  for moduleName in "${modules[@]}"; do
    serenity.actions.help.printModuleHelp "$moduleType" "$moduleName"
  done
  
  indentation="${indentation%  }"
}

serenity.actions.help.printModuleHelp() {
  local helpFunc
  local line
  helpFunc="$(printf ${serenity_APIs_help["$1"]} "$2")"
  if serenity.tools.isFunction "$helpFunc"; then
    "$helpFunc" | while IFS= read line; do
      echo "$indentation$line"
    done
    echo
    echo
  fi
}
