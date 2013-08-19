#    serenity - An automated episode renamer.
#    Copyright (C) 2010-2013  Florian Léger
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


# serenity.actions.tokens.run [TOKEN_TYPES...]
# Rename action entry point

serenity.actions.tokens.help() {
cat << EOM
tokens FILE [TOKEN_TYPES...]

  Show token values of the specified TOKEN_TYPES for FILE.
  If TOKEN_TYPES is not specified, show all tokens.
EOM
}

serenity.actions.tokens.run() {
  serenity.processing.enableDatasources: "${serenity_conf_datasources[@]}" -- serenity.actions.tokens._run "$@"
}

serenity.actions.tokens._run() {
  # Process files
  serenity.tokens: serenity.actions.tokens.definitions.global "${@}" || {
    serenity.debug.error "Something went wrong."
    return 1
  }
  serenity.debug.info "Done."
}

# Processing definitions

# serenity.actions.tokens.definitions.global FILE
#
# Global tokens process definition for FILE [TOKEN_TYPES...]
#
# Closures: serenity:, serenity.actions.tokens.run, serenity.tokens:
serenity.actions.tokens.definitions.global() {
  local -a flat=()
  local key
  local outputDirectory

  if [[ -z "${rename_opt_outputDirectory}" ]]; then
    outputDirectory="$(dirname "${1}")"
  else
    outputDirectory="${rename_opt_outputDirectory}"
  fi
  outputDirectory="$(readlink -f "$outputDirectory")"

  serenity.tokens- serenity.tokens.set "_::input_filename" "$(basename "${1}")"
  serenity.tokens- serenity.processing.callFilterChainOnToken "$serenity_conf_globalPreprocessing" "_::input_filename"
  serenity.tokens- serenity.processing.tokenization "_::input_filename"
  flat=()
  for key in "${!serenity_conf_tokenPreprocessing[@]}"; do
    flat+=("${key}" "${serenity_conf_tokenPreprocessing[${key}]}")
  done
  serenity.tokens- serenity.processing.tokenProcessing "${flat[@]}"
  serenity.tokens- serenity.processing.split serenity.actions.tokens.definitions.perEpisode
  serenity.tokens- serenity.processing.aggregate "${serenity_conf_aggregatorPriorities[@]}"
  flat=()
  for key in "${!serenity_conf_tokenPostprocessing[@]}"; do
    flat+=("${key}" "${serenity_conf_tokenPostprocessing[${key}]}")
  done
  serenity.tokens- serenity.processing.tokenProcessing "${flat[@]}"
  serenity.tokens- serenity.processing.format "_::output_filename" "${serenity_conf_formatting[@]}"

  serenity.tokens- serenity.processing.callFilterChainOnToken "$serenity_conf_globalPostprocessing" "_::output_filename"
  serenity.tokens- serenity.actions.tokens.print "${@:2}"
}

# Per-episode tokens process definition
#
# Closures: serenity:, serenity.tokens:
serenity.actions.tokens.definitions.perEpisode() {
  serenity.tokens- serenity.processing.queryDatasources "${serenity_conf_datasources[@]}"
}


# serenity.actions.tokens.print [TOKEN_TYPES...]
#
# Print tokens
#
# Closure: serenity.actions.tokens.run, serenity.tokens:
serenity.actions.tokens.print() {
  if [[ $# -gt 0 ]]; then
    local tt
    for tt in "${@}"; do
      serenity.actions.token.printToken "$tt" "$(serenity.tokens.get "$tt")"
    done
  else
    serenity.tokens.forEach serenity.actions.token.printToken
  fi
}

serenity.actions.token.printToken() {
  echo "$1=$2"
}
