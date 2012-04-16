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
  serenity.pipeline.add serenity.debug.trace serenity.actions.processing.callFilterChain "$serenity_conf_globalPreprocessing"
  # FIXME: pass configuration
  serenity.pipeline.add serenity.debug.trace serenity.actions.processing.tokenization
  if ! "${serenity_conf_test}"; then
    flat=()
    for key in "${!serenity_conf_tokenPreprocessing[@]}"; do
      flat+=("${key}" "${serenity_conf_tokenPreprocessing[${key}]}")
    done
    serenity.pipeline.add serenity.debug.trace serenity.actions.processing.tokenProcessing "${flat[@]}"
    serenity.pipeline.add serenity.debug.trace serenity.actions.processing.split
    serenity.pipeline.add serenity.debug.trace serenity.actions.processing.aggregate
    flat=()
    for key in "${!serenity_conf_tokenPostprocessing[@]}"; do
      flat+=("${key}" "${serenity_conf_tokenPostprocessing[${key}]}")
    done
    serenity.pipeline.add serenity.debug.trace serenity.actions.processing.tokenProcessing "${flat[@]}"
    serenity.pipeline.add serenity.debug.trace serenity.actions.processing.formatting "${serenity_conf_formatting[@]}"
    serenity.pipeline.add serenity.debug.trace serenity.actions.processing.callFilterChain "$serenity_conf_globalPostprocessing"
    # Extension
    if [ "x$serenity_conf_keepExtension" = "xyes" ]; then
      serenity.pipeline.add serenity.debug.trace serenity.actions.processing.extension "${1}"
    fi
  fi
}

serenity.actions.processing.definition.perEpisode() {
  serenity.pipeline.add serenity.debug.trace serenity.actions.processing.refining "${serenity_conf_refiningBackends[@]}"
}

# Processing steps

# Call a given filter chain
serenity.actions.processing.callFilterChain() {
  if [ "x${1}" != "x" ]; then
    serenity.pipeline.execute "serenity.conf.chains.${1}"
  else
    echo "$(< /dev/stdin)"
  fi
}

# Tokenization (with token environment)
serenity.actions.processing.tokenization() {
  local inputBuffer="$(< /dev/stdin)"
  local offset=0
  local length
  local -a commandLine=()
  for length in "${serenity_conf__tokenizerLengths[@]}"; do
    commandLine=("${serenity_conf__tokenizers[@]:${offset}:${length}}")
    offset=$(( ${offset} + ${length} ))
    commandLine[0]="serenity.tokenizers.${commandLine[0]}.run"
    local -A serenity__currentTokens=()
    "${commandLine[@]}" <<< "${inputBuffer}" &&
    serenity.debug.debug "Tokenization: success with ${commandLine[*]}" &&
    # Token serialization
    serenity.tokens.serialize &&
    return 0 ||
    serenity.debug.debug "Tokenization: failure with ${commandLine[*]}"
  done
  serenity.debug.error "Tokenization: file name can't be tokenized"
  return 1
}

serenity.actions.processing.split() {
  # Tokens deserialization
  local -A serenity__currentTokens=()
  serenity.tokens.deserialize

  local i
  local returnCode=1
  for i in "${serenity_conf_splitterPriorities[@]}"; do
    if serenity.splitters."$i".checkRequirements; then
      serenity.debug.debug "Split: running $i splitter"
      serenity.splitters."$i".run
      returnCode=0
      break
    fi
  done
  
  return "$returnCode"
}

# Token processing (with token environment)
serenity.actions.processing.tokenProcessing() {
  # Processing chains unpacking
  local -A tokenProcessing=()
  until [ "$#" -lt 2 ]; do
    tokenProcessing["${1}"]="${2}"
    shift 2
  done

  # Tokens deserialization
  local -A serenity__currentTokens=()
  serenity.tokens.deserialize

  # Processing
  local tokenType
  for tokenType in "${!serenity__currentTokens[@]}"; do
    if serenity.tools.contains "${tokenType#*::}" "${!tokenProcessing[@]}"; then
      serenity.tokens.set "${tokenType}" \
        "$(serenity.actions.processing.callFilterChain "${tokenProcessing["${tokenType#*::}"]}" < <(serenity.tokens.get "${tokenType}"))"
    else
      serenity.tokens.set "${tokenType}" \
        "$(serenity.actions.processing.callFilterChain "${tokenProcessing["default"]}" < <(serenity.tokens.get "${tokenType}"))"
    fi
  done
  # Token serialization
  serenity.tokens.serialize
}

# Token refining
serenity.actions.processing.refining() {
  # Tokens deserialization
  local -A serenity__currentTokens=()
  serenity.tokens.deserialize

  local backend
  for backend; do
    "serenity.refiningBackends.${backend}.run" &&
    serenity.debug.debug "Refining: success with ${backend}" &&
    # Token serialization
    serenity.tokens.serialize &&
    return 0 ||
    serenity.debug.debug "Refining: failure with ${backend}"
  done
  return 1
}

serenity.actions.processing.aggregate() {
  # Tokens deserialization
  local -A serenity__currentTokens=()
  serenity.tokens.deserialize
  
  local i
  for i in "${serenity_conf_aggregatorPriorities[@]}"; do
    if serenity.aggregators."$i".checkRequirements; then
      serenity.debug.debug "Aggregator: running $i aggregator"
      serenity.aggregators."$i".run
    fi
  done
  
  serenity.tokens.serialize
}

# Token formatting
serenity.actions.processing.formatting() {
  # Tokens deserialization
  local -A serenity__currentTokens=()
  serenity.tokens.deserialize
  # Note: Shouldn't this be "${@:1}"?
  "serenity.formatters.${1}.run" "${@:2}"
}

serenity.actions.processing.extension() {
  local ext=""
  [[ "${1}" =~ ^.*\..*$ ]] && ext=".${1##*.}"
  echo "$(< /dev/stdin)${ext}"
}

serenity.actions.processing.move() {
  mkdir -p "$(dirname "${2}")" &&
  mv "${serenity_conf_mvArgs[@]}" "${1}" "${2}"
}
