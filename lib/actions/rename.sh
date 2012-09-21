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


# serenity.actions.rename.run [OPTIONS]... FILES...
# Rename action entry point

serenity.actions.rename.help() {
cat << EOM
rename [OPTIONS] FILES...

  Rename FILES.

  Options:
    -d              dry-run; don't rename FILES, only print their new basename
    -o <string>     set output directory [default: same as the input files]
    -f              do not prompt before overwriting
    -i              prompt before overwrite
    -b              backup each existing destination file
    -n              do not overwrite an existing file
EOM
}

serenity.actions.rename.run() {
  # Options
  local rename_opt_dryRun=false
  local rename_opt_outputDirectory=""
  local -a rename_opt_mvOpts=()

  # Parse commandline
  local opt
  local OPTARG
  local OPTIND=1
  while getopts 'do:fibn' opt; do
    case "$opt" in
      d) rename_opt_dryRun=true;;
      o) rename_opt_outputDirectory="${OPTARG}";;
      f) rename_opt_mvOpts+=(-f);;
      i) rename_opt_mvOpts+=(-i);;
      b) rename_opt_mvOpts+=(-b);;
      n) rename_opt_mvOpts+=(-n);;
    esac
  done
  shift $((${OPTIND} - 1))

  serenity.processing.refiners: "${serenity_conf_refiningBackends[@]}" -- serenity.actions.rename._run "$@"
}

serenity.actions.rename._run() {
  # Process files
  local f
  for f; do
    serenity.tokens: serenity.actions.rename.definitions.global "${f}" || {
      serenity.debug.error "Something went wrong."
      return 1
    }
  done
  serenity.debug.info "Done."
}

# Processing definitions

# serenity.actions.rename.definitions.global FILE
#
# Global rename process definition for FILE
#
# Closures: serenity.main, serenity.actions.rename.run, serenity.tokens:
serenity.actions.rename.definitions.global() {
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
  serenity.tokens- serenity.processing.split serenity.actions.rename.definitions.perEpisode
  serenity.tokens- serenity.processing.aggregate "${serenity_conf_aggregatorPriorities[@]}"
  flat=()
  for key in "${!serenity_conf_tokenPostprocessing[@]}"; do
    flat+=("${key}" "${serenity_conf_tokenPostprocessing[${key}]}")
  done
  serenity.tokens- serenity.processing.tokenProcessing "${flat[@]}"
  serenity.tokens- serenity.processing.format "_::output_filename" "${serenity_conf_formatting[@]}"
  
  serenity.tokens- serenity.processing.callFilterChainOnToken "$serenity_conf_globalPostprocessing" "_::output_filename"
  if ! ${rename_opt_dryRun}; then
    serenity.tokens- serenity.actions.rename.move "$1" "$outputDirectory" "_::output_filename"
  else
    serenity.tokens- serenity.tokens.get "_::output_filename"
  fi
}

# Per-episode rename process definition
#
# Closures: serenity.main, serenity.tokens:
serenity.actions.rename.definitions.perEpisode() {
  serenity.tokens- serenity.processing.refining "${serenity_conf_refiningBackends[@]}"
}

# serenity.actions.rename.move SOURCE DEST_DIR OUTPUT_FILENAME_TOKEN
#
# Move a SOURCE to DEST_DIR/OUTPUT_FILENAME_TOKEN value
#
# Closure: serenity.actions.rename.run, serenity.tokens.execute
serenity.actions.rename.move() {
  mkdir -p "${2}" &&
  mv "${rename_opt_mvOpts[@]}" "${1}" "${2}/$(serenity.tokens.get "${3}")" || {
    serenity.debug.error "Couldn't move ${1} to ${2}/$(serenity.tokens.get "${3}")"
    return 1
  }
}
