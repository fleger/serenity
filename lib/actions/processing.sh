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


# Processing action entry point
serenity.actions.processing.run() {
  serenity.actions.processing.processFile "${1}" || {
    "${serenity_conf_test}" || serenity.debug.error "Something went wrong."
    return 1
  }
  serenity.debug.info "Done."
}

# Process a file
serenity.actions.processing.processFile() {
  serenity.debug.info "Processing ${1}..."
  local finalName=""
  local fileName="$(basename "${1}")"
  
  finalName="$(serenity.pipeline.execute serenity.actions.processing.definitions.global "${fileName}" <<< "${fileName}")" || {
    "${serenity_conf_test}" || serenity.debug.error "Processing failed!"
    return 1
  }
  if ! ${serenity_conf_test}; then
    if ! ${serenity_conf_dryRun}; then
      serenity.actions.processing.move "${1}" "$(readlink -f "${serenity_conf_outputPrefix}")/${finalName}" || {
        serenity.debug.error "Couldn't move ${1} to $(readlink -f "${serenity_conf_outputPrefix}")/${finalName}"
        return 1
      }
    else
      echo "${finalName}"
    fi
  fi
}

# Processing definitions
serenity.actions.processing.definitions.global() {
  local -a flat=()
  local key
  serenity.pipeline.add serenity.debug.trace serenity.core.callFilterChain "$serenity_conf_globalPreprocessing"
  # FIXME: pass configuration
  serenity.pipeline.add serenity.debug.trace serenity.core.tokenization
  if ! "${serenity_conf_test}"; then
    flat=()
    for key in "${!serenity_conf_tokenPreprocessing[@]}"; do
      flat+=("${key}" "${serenity_conf_tokenPreprocessing[${key}]}")
    done
    serenity.pipeline.add serenity.debug.trace serenity.core.tokenProcessing "${flat[@]}"
    serenity.pipeline.add serenity.debug.trace serenity.core.split serenity.pipeline.execute serenity.actions.processing.definitions.perEpisode
    serenity.pipeline.add serenity.debug.trace serenity.core.aggregate
    flat=()
    for key in "${!serenity_conf_tokenPostprocessing[@]}"; do
      flat+=("${key}" "${serenity_conf_tokenPostprocessing[${key}]}")
    done
    serenity.pipeline.add serenity.debug.trace serenity.core.tokenProcessing "${flat[@]}"
    serenity.pipeline.add serenity.debug.trace serenity.core.formatting "${serenity_conf_formatting[@]}"
    serenity.pipeline.add serenity.debug.trace serenity.core.callFilterChain "$serenity_conf_globalPostprocessing"
  fi
}

serenity.actions.processing.definitions.perEpisode() {
  serenity.pipeline.add serenity.debug.trace serenity.core.refining "${serenity_conf_refiningBackends[@]}"
}

serenity.actions.processing.move() {
  mkdir -p "$(dirname "${2}")" &&
  mv "${serenity_conf_mvArgs[@]}" "${1}" "${2}"
}
