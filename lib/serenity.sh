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

# Main

set -eo pipefail

# Main entry point
serenity.main() {
  # Load debugging routines
  . "${serenity_env_lib}/debug.sh" || {
    echo "Serenity: failed to load ${serenity_env_lib}/debug.sh"
    exit 1;
  }

  # Load libraries
  local serenity_conf_verbosity=$serenity_debug_info
  local -a libraries=("${serenity_env_lib}/nakedconf.sh" "${serenity_env_lib}/tools.sh"
                      "${serenity_env_lib}/tokens.sh" "${serenity_env_lib}/pipeline.sh"
                      "${serenity_env_lib}/actions/"*.sh
                      "${serenity_env_lib}/aggregators/"*.sh
                      "${serenity_env_lib}/filters/"*.sh
                      "${serenity_env_lib}/formatters/"*.sh
                      "${serenity_env_lib}/refining/"*.sh
                      "${serenity_env_lib}/splitters/"*.sh
                      "${serenity_env_lib}/tokenizers/"*.sh)
  local l=""
  for l in "${libraries[@]}"; do
    [ -f "${l}" ] &&
    . "${l}" && {
      serenity.debug.debug "Serenity: ${l} loaded"
    } || {
      serenity.helpers.crash "Serenity: failed to load ${l}"
    }
  done

  # Load user configuration
  serenity.helpers.loadUserConfig

  # Parse command line
  local opt
  local action="processing"
  local OPTARG
  local OPTIND=1
  while getopts dto:fibnh opt; do
    case "$opt" in
      d) serenity_conf_dryRun=true;;
      t) serenity_conf_test=true;;
#       l)
#         serenity_conf_list=${OPTARG}
#         action="list";;
      o) serenity_conf_outputPrefix="${OPTARG}";;
      f) serenity_conf_mvArgs+=(-f);;
      i) serenity_conf_mvArgs+=(-i);;
      b) serenity_conf_mvArgs+=(-b);;
      n) serenity_conf_mvArgs+=(-n);;
      h|?) action="help";;
    esac
  done
  shift $((${OPTIND} - 1))

  # Show help if no arguments
  (($# < 1)) && [ "x${action}" = "xprocessing" ] && action="help"

  serenity.debug.debug "Serenity: action $action"
  "serenity.actions.${action}" "${@}"
}

# Helpers

# Crash serenity
serenity.helpers.crash() {
  serenity.debug.critical "${@}"
  exit 1
}

# Load (source) the configuration files defined in serenity_env_conf
serenity.helpers.loadUserConfig() {
  local -a loadedFiles=()
  local f
  # Do not load the same file twice
  serenity.debug.debug "Config: conf files: ${serenity_env_conf[@]}"
  for f in "${serenity_env_conf[@]}"; do
    serenity.debug.debug "Config: Trying to load $f" &&
    [ -f "$f" ] &&
    f="$(readlink -f "${f}")" &&
    ! serenity.tools.contains "$f" "${loadedFiles[@]}" &&
    serenity.debug.debug "Config: ${f} is not already loaded" &&
    loadedFiles+=("${f}") &&
    serenity.debug.debug "Config: loading configuration file $f" &&
    . "${f}"
  done
}

# serenity.actions.list() {
#   local i
#   case ${serenity_conf_list} in
#     "preprocessing")
#       for i in "${serenity_conf_preprocessing[@]}"; do
#         echo ${i}
#       done;;
#     "postprocessing")
#       for i in "${serenity_conf_postprocessing[@]}"; do
#         echo ${i}
#       done;;
#     "tokenizers")
#       for i in "${!serenity_conf_tokenizers_regex[@]}"; do
#         echo "${serenity_conf_tokenizers_regex[$i]}"
#         echo "${serenity_conf_tokenizers_associations[$i]}"
#       done;;
#     "backends")
#       for i in "${serenity_conf_backends[@]}"; do
#         echo ${i}
#       done;;
#     "formatting")
#       echo ${serenity_conf_formatting_format}
#       echo ${serenity_conf_formatting_associations};;
#     *)
#       echo "${serenity_conf_list} is not a valid parameter." >&2
#       return 1;;
#   esac
# }
