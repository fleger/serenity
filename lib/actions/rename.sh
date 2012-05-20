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

  # Process files
  local f
  for f; do
    serenity.actions.rename.processFile "${f}" || {
      serenity.debug.error "Something went wrong."
      return 1
    }
  done
  serenity.debug.info "Done."
}

# serenity.actions.rename.processFile FILE
# Process FILE
# Closure: serenity.actions.rename.run
serenity.actions.rename.processFile() {
  serenity.debug.info "Processing ${1}..."
  local finalName
  local fileName="$(basename "${1}")"
  local outputPath

  if [[ -z "${rename_opt_outputDirectory}" ]]; then
    outputDirectory="$(dirname "${1}")"
  else
    outputDirectory="${rename_opt_outputDirectory}"
  fi

  finalName="$(serenity.pipeline.execute serenity.actions.rename.definitions.global <<< "${fileName}")" || {
    serenity.debug.error "Processing failed! ($finalName)"
    return 1
  }

  if ! ${rename_opt_dryRun}; then
    serenity.actions.rename.move "${1}" "$(readlink -f "${outputDirectory}")/${finalName}" || {
      serenity.debug.error "Couldn't move ${1} to $(readlink -f "${outputDirectory}")/${finalName}"
      return 1
    }
  else
    echo "${finalName}"
  fi
}

# Processing definitions

# Global rename process definition
# Closures: serenity.main, serenity.pipeline.execute
serenity.actions.rename.definitions.global() {
  local -a flat=()
  local key
  serenity.pipeline.add serenity.debug.trace serenity.processing.callFilterChain "$serenity_conf_globalPreprocessing"
  # FIXME: pass configuration
  serenity.pipeline.add serenity.debug.trace serenity.processing.tokenization
  flat=()
  for key in "${!serenity_conf_tokenPreprocessing[@]}"; do
    flat+=("${key}" "${serenity_conf_tokenPreprocessing[${key}]}")
  done
  serenity.pipeline.add serenity.debug.trace serenity.processing.tokenProcessing "${flat[@]}"
  serenity.pipeline.add serenity.debug.trace serenity.processing.split serenity.pipeline.execute serenity.actions.rename.definitions.perEpisode
  serenity.pipeline.add serenity.debug.trace serenity.processing.aggregate "${serenity_conf_aggregatorPriorities[@]}"
  flat=()
  for key in "${!serenity_conf_tokenPostprocessing[@]}"; do
    flat+=("${key}" "${serenity_conf_tokenPostprocessing[${key}]}")
  done
  serenity.pipeline.add serenity.debug.trace serenity.processing.tokenProcessing "${flat[@]}"
  serenity.pipeline.add serenity.debug.trace serenity.processing.format "${serenity_conf_formatting[@]}"
  serenity.pipeline.add serenity.debug.trace serenity.processing.callFilterChain "$serenity_conf_globalPostrename"
}

# Per-episode rename process definition
# Closures: serenity.main, serenity.pipeline.execute
serenity.actions.rename.definitions.perEpisode() {
  serenity.pipeline.add serenity.debug.trace serenity.processing.refining "${serenity_conf_refiningBackends[@]}"
}

# serenity.actions.rename.move SOURCE DEST
# Move a SOURCE to DEST
# Closure: serenity.actions.rename.run
serenity.actions.rename.move() {
  mkdir -p "$(dirname "${2}")" &&
  mv "${rename_opt_mvOpts[@]}" "${1}" "${2}"
}