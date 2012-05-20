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

# serenity.main ACTION ARGS...
# Main entry point
serenity.main() {
  # Manual early load of the debugging routines
  source "${serenity_env_lib}/debug.sh" || {
    echo "Serenity: failed to load ${serenity_env_lib}/debug.sh"
    exit 1;
  }

  local serenity_conf_verbosity=$serenity_debug_info

  local l

  local -A serenity_APIs=(["actions"]='serenity\.actions\.([^.]+)\.run'
                          ["aggregators"]='serenity\.aggregators\.([^.]+)\.run'
                          ["filters"]='serenity\.filters\.(.+)'
                          ["formatters"]='serenity\.formatters\.([^.]+)\.run'
                          ["refining"]='serenity\.refiningBackends\.([^.]+)\.run'
                          ["splitters"]='serenity\.splitters\.([^.]+)\.run'
                          ["tokenizers"]='serenity\.tokenizers\.([^.]+)\.run')

  local -A serenity_APIs_help=( ["actions"]='serenity.actions.%s.help'
                                ["aggregators"]='serenity.aggregators.%s.help'
                                ["filters"]='serenity.filters.%s.help'
                                ["formatters"]='serenity.formatters.%s.help'
                                ["refining"]='serenity.refiningBackends.%s.help'
                                ["splitters"]='serenity.splitters.%s.help'
                                ["tokenizers"]='serenity.tokenizers.%s.help')

  # Load the libraries
  local -a libraries=("${serenity_env_lib}/nakedconf.sh"
                      "${serenity_env_lib}/tools.sh"
                      "${serenity_env_lib}/tokens.sh"
                      "${serenity_env_lib}/pipeline.sh"
                      "${serenity_env_lib}/processing.sh")

  for l in "${!serenity_APIs[@]}"; do
    libraries+=("${serenity_env_lib}/${l}/"*.sh)
  done

  for l in "${libraries[@]}"; do
    [[ -f "${l}" ]] &&
    source "${l}" && {
      serenity.debug.debug "Serenity: ${l} loaded"
    } || {
      serenity.crash "Serenity: failed to load ${l}"
    }
  done

  # Load & check user configuration
  serenity.loadUserConfig "${serenity_env_conf[@]}"
  serenity.conf.check.run

  # Parse commandline
  local action="help"
  (( $# > 0 )) && {
    action="$1"
    shift
  }

  if serenity.tools.isFunction "serenity.actions.${action}.run"; then
    serenity.debug.debug "Serenity: running $action"
    "serenity.actions.${action}.run" "${@}"
  else
    serenity.crash "Serenity: no action named $action"
  fi
}

# serenity.crash MESSAGE
# Crash serenity and show MESSAGE
serenity.crash() {
  serenity.debug.critical "${@}"
  exit 1
}

# serenity.loadUserConfig FILE...
# Source the configuration files
serenity.loadUserConfig() {
  local -a loadedFiles=()
  local f

  # Do not load the same file twice
  serenity.debug.debug "Config: conf files: ${@}"
  for f in "${@}"; do
    serenity.debug.debug "Config: Trying to load ${f}" &&
    [[ -f "${f}" ]] &&
    f="$(readlink -f "${f}")" &&
    ! serenity.tools.contains "${f}" "${loadedFiles[@]}" &&
    serenity.debug.debug "Config: ${f} is not already loaded" &&
    loadedFiles+=("${f}") &&
    serenity.debug.debug "Config: loading configuration file ${f}" &&
    source "${f}"
  done
}
