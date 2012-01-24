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
serenity.actions.processing() {
  serenity.processing.processFile "${1}" || {
    "${serenity_conf_test}" || serenity.debug.error "Something went wrong."
    return 1
  }
  serenity.debug.info "Done."
}

# Process a file
serenity.processing.processFile() {
  serenity.debug.info "Processing ${1}..."
  local finalName=""
  local fileName="$(basename "${1}")"
  
  finalName="$(serenity.pipeline.execute serenity.processing.processDefinition "${fileName}" <<< "${fileName}")" || {
    "${serenity_conf_test}" || serenity.debug.error "Processing failed!"
    return 1
  }
  if ! ${serenity_conf_test}; then
    if ! ${serenity_conf_dryRun}; then
      serenity.processing.move "${1}" "$(readlink -f "${serenity_conf_outputPrefix}")/${finalName}" || {
        serenity.debug.error "Couldn't move ${1} to $(readlink -f "${serenity_conf_outputPrefix}")/${finalName}"
        return 1
      }
    else
      echo "${finalName}"
    fi
  fi
}

# For debugging purposes
serenity.processing.trace() {
  # FIXME: get rid of cat
  local inputBuffer="$(cat)"
  serenity.debug.debug "Trace [$1]: begin trace"
  serenity.debug.debug "Trace [$1]: calling $*"
  serenity.debug.debug "Trace [$1]: begin stdin dump"
  serenity.debug.debug "$inputBuffer"
  serenity.debug.debug "Trace [$1]: end stdin dump"
  local outputBuffer
  outputBuffer="$("${@}" <<< "${inputBuffer}")"
  local errorCode="$?"
  serenity.debug.debug "Trace [$1]: error code: $errorCode"
  serenity.debug.debug "Trace [$1]: begin stdout dump"
  serenity.debug.debug "$outputBuffer"
  serenity.debug.debug "Trace [$1]: end stdout dump"
  serenity.debug.debug "Trace [$1]: end trace"
  echo "${outputBuffer}"
  return $errorCode
}

# Processing algorithm
serenity.processing.processDefinition() {
  serenity.pipeline.add serenity.processing.trace serenity.processing.callFilterChain "$serenity_conf_globalPreprocessing"
  # FIXME: pass configuration
  serenity.pipeline.add serenity.processing.trace serenity.processing.tokenization
  if ! "${serenity_conf_test}"; then
    local -a flat=()
    local key
    flat=()
    for key in "${!serenity_conf_tokenPreprocessing[@]}"; do
      flat+=("${key}" "${serenity_conf_tokenPreprocessing[${key}]}")
    done
    serenity.pipeline.add serenity.processing.trace serenity.processing.tokenProcessing "${flat[@]}"
    serenity.pipeline.add serenity.processing.trace serenity.processing.refining "${serenity_conf_refiningBackends[@]}"
      flat=()
    for key in "${!serenity_conf_tokenPostprocessing[@]}"; do
      flat+=("${key}" "${serenity_conf_tokenPostprocessing[${key}]}")
    done
    serenity.pipeline.add serenity.processing.trace serenity.processing.tokenProcessing "${flat[@]}"
    serenity.pipeline.add serenity.processing.trace serenity.processing.formatting "${serenity_conf_formatting[@]}"
    serenity.pipeline.add serenity.processing.trace serenity.processing.callFilterChain "$serenity_conf_globalPostprocessing"
    # Extension
    if [ "x$serenity_conf_keepExtension" = "xyes" ]; then
      serenity.pipeline.add serenity.processing.trace serenity.processing.extension "${1}"
    fi
  fi
}

# Processing steps

# Call a given filter chain
serenity.processing.callFilterChain() {
  if [ "x${1}" != "x" ]; then
    serenity.pipeline.execute "serenity.conf.chains.${1}"
  else
    cat
  fi
}

# Tokenization (with token environment)
serenity.processing.tokenization() {
  # FIXME: get rid of cat
  local inputBuffer="$(cat)"
  local offset=0
  local length
  local -a commandLine=()
  for length in "${serenity_conf__tokenizerLengths[@]}"; do
    commandLine=("${serenity_conf__tokenizers[@]:${offset}:${length}}")
    offset=$(( ${offset} + ${length} ))

    local -A serenity__currentTokens=()
    serenity.tokenizers."${commandLine[@]}" <<< "${inputBuffer}" &&
    serenity.debug.debug "Tokenization: success with ${commandLine[*]}" &&
    # Token serialization
    serenity.tokens.serialize &&
    return 0 ||
    serenity.debug.debug "Tokenization: failure with ${commandLine[*]}"
  done
  serenity.debug.error "Tokenization: file name can't be tokenized"
  return 1
}

# Token processing (with token environment)
serenity.processing.tokenProcessing() {
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
    if serenity.tools.contains "${tokenType}" "${!tokenProcessing[@]}"; then
      serenity__currentTokens["${tokenType}"]="$(serenity.processing.callFilterChain "${tokenProcessing[${tokenType}]}" <<< "${serenity__currentTokens["${tokenType}"]}")"
    else
      serenity__currentTokens["${tokenType}"]="$(serenity.processing.callFilterChain "${tokenProcessing["default"]}" <<< "${serenity__currentTokens["${tokenType}"]}")"
    fi
  done
  # Token serialization
  serenity.tokens.serialize
}

# Token refining
serenity.processing.refining() {
  # Tokens deserialization
  local -A serenity__currentTokens=()
  serenity.tokens.deserialize

  local backend
  for backend; do
    serenity.refiningBackends.${backend} &&
    serenity.debug.debug "Refining: success with ${backend}" &&
    # Token serialization
    serenity.tokens.serialize &&
    return 0 ||
    serenity.debug.debug "Refining: failure with ${backend}"
  done
  return 1
}

# Token formatting
serenity.processing.formatting() {
  # Tokens deserialization
  local -A serenity__currentTokens=()
  serenity.tokens.deserialize

  local format="${1}"
  shift

  local -a fields=()
  local tokenType=""

  for tokenType; do
    fields+=("$(serenity.tokens.get "${tokenType}")")
  done

  printf "${format}" "${fields[@]}"
}

serenity.processing.extension() {
  local ext=""
  [[ "${1}" =~ ^.*\..*$ ]] && ext=".${1##*.}"
  # FIXME: get rid of cat
  echo "$(cat)${ext}"
}

serenity.processing.move() {
  mkdir -p "$(dirname "${2}")" &&
  mv "${serenity_conf_mvArgs[@]}" "${1}" "${2}"
}



