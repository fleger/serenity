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
  
  finalName="$(serenity.pipeline.execute serenity.processing.globalProcessDefinition "${fileName}" <<< "${fileName}")" || {
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
  local errorCode
  if [ "x${serenity_conf_tracing}" = "xyes" ]; then
    # FIXME: get rid of cat
    local inputBuffer="$(cat)"
    serenity.debug.debug "Trace [$1]: begin trace"
    serenity.debug.debug "Trace [$1]: calling $*"
    serenity.debug.debug "Trace [$1]: begin stdin dump"
    serenity.debug.debug "$inputBuffer"
    serenity.debug.debug "Trace [$1]: end stdin dump"
    local outputBuffer
    outputBuffer="$("${@}" <<< "${inputBuffer}")"
    errorCode="$?"
    serenity.debug.debug "Trace [$1]: error code: $errorCode"
    serenity.debug.debug "Trace [$1]: begin stdout dump"
    serenity.debug.debug "$outputBuffer"
    serenity.debug.debug "Trace [$1]: end stdout dump"
    serenity.debug.debug "Trace [$1]: end trace"
    echo "${outputBuffer}"
  else
    "${@}"
    errorCode="$?"
  fi
  return $errorCode
}

# Processing algorithms
serenity.processing.globalProcessDefinition() {
  serenity.pipeline.add serenity.processing.trace serenity.processing.callFilterChain "$serenity_conf_globalPreprocessing"
  # FIXME: pass configuration
  serenity.pipeline.add serenity.processing.trace serenity.processing.tokenization
  if ! "${serenity_conf_test}"; then
    serenity.pipeline.add serenity.processing.trace serenity.processing.perEpisodeProcessing
    serenity.pipeline.add serenity.processing.trace serenity.processing.summarize
    serenity.pipeline.add serenity.processing.trace serenity.processing.formatting "${serenity_conf_formatting[@]}"
    serenity.pipeline.add serenity.processing.trace serenity.processing.callFilterChain "$serenity_conf_globalPostprocessing"
    # Extension
    if [ "x$serenity_conf_keepExtension" = "xyes" ]; then
      serenity.pipeline.add serenity.processing.trace serenity.processing.extension "${1}"
    fi
  fi
}


serenity.processing.perEpisodeProcessDefinition() {
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

serenity.processing.perEpisodeProcessing() {
  # Tokens deserialization
  local -A serenity__currentTokens=()
  serenity.tokens.deserialize

  local n
  local i
  
  if [ -n "$(serenity.tokens.get first_episode)" ] && [ -n "$(serenity.tokens.get last_episode)" ]; then
    # Multi-episode range mode
    serenity.debug.debug "PerEpisodeProcessing: episode range mode"
    i=0
    for n in $(seq "$(serenity.tokens.get first_episode)" "$(serenity.tokens.get last_episode)"); do
      i=$(( $i + 1 ))
      serenity.tokens.set episode "${n}"
      serenity.tokens.serialize | serenity.pipeline.execute serenity.processing.perEpisodeProcessDefinition | serenity.tokens.filter.copyPrefix "" "$i"
    done
  elif [ -n "$(serenity.tokens.get 1::episode)" ]; then
    # Multi-episode numbers mode
    serenity.debug.debug "PerEpisodeProcessing: multi episodes mode"
    i=1
    while [ -n "$(serenity.tokens.get ${i}::episode)" ]; do
      serenity.tokens.serialize | serenity.tokens.filter.copyPrefix "${i}" "" | serenity.pipeline.execute serenity.processing.perEpisodeProcessDefinition | serenity.tokens.filter.copyPrefix "" "$i"
      i=$(( i + 1 ))
    done
    i=$(( i - 1 ))
  else
    # Single episode mode
    serenity.debug.debug "PerEpisodeProcessing: single episode mode"
    serenity.tokens.serialize | serenity.pipeline.execute serenity.processing.perEpisodeProcessDefinition | serenity.tokens.filter.copyPrefix "" "1"
    i=1
  fi

  serenity.tokens.addToStream "_::episode_count" "$i"
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

serenity.processing.stripTitle() {
  local title="$1"
  shift
  
  local previous=""

  while [ "${title}" != "${previous}" ]; do
    previous="${title}"
    for re in "${serenity_conf_multipartStripList[@]}"; do
      [[ "$title" =~ $re ]] &&
      title="${title%${BASH_REMATCH[1]}}"
    done
  done

  echo "${title}"
}


serenity.processing.helpers.commonTokens() {
  local -A tokenValues=()
  local -a badTokens=()
  local dest="$1"
  [ -n "$dest" ] && dest="$dest::"
  shift
  local key
  for key in "${!serenity__currentTokens[@]}"; do
    {
      [[ "$key" == *::* ]] &&
      serenity.tools.contains "${key%%::*}" "${@}" &&
    } || {
      [[ "$key" != *::* ]] &&
      serenity.tools.contains "" "${@}" &&
    } && {
      if ! serenity.tools.contains "${key#*::}" "${badTokens[@]}"; then
        if serenity.tools.contains "${key#*::}" "${!tokenValues[@]}"; then
          if [[ "$(serenity.tokens.get "$key")" != "${tokenValues["${key#*::}"]}" ]]; then
            badTokens+=("${key#*::}")
          fi
        else
          tokenValues["${key#*::}"]="$(serenity.tokens.get "$key")"
        fi
      fi
    }
  done
  for key in "${!tokenValues[@]}"; do
    serenity.tools.contains "${key}" "${badTokens[@]}" ||
    serenity.tokens.set "$dest$key" "${tokenValues["$key"]}"
  done
}

serenity.processing.summarize() {
  # Tokens deserialization
  local -A serenity__currentTokens=()
  serenity.tokens.deserialize
  if [ "$(serenity.tokens.get "_::episode_count")" = "1" ]; then
    # Single episode
    serenity.debug.debug "Summarize: single episode mode"
    serenity.processing.helpers.commonTokens "1" ""
  else
    # Multiple episodes
    serenity.debug.debug "Summarize: multi episodes mode"
    local e
    serenity.processing.helpers.commonTokens common $(seq 1 "$(serenity.tokens.get "_::episode_count")")
    local -a titles=("$(serenity.tokens.get 1::title)")
    local lastEpisode="$(serenity.tokens.get 1::episode)"
    local firstEpisode="$(serenity.tokens.get 1::episode)"
    
    for e in $(seq 2 "$(serenity.tokens.get "_::episode_count")"); do
      titles+=("$(serenity.tokens.get "$e::title")")
      if [ "$(serenity.tokens.get "$e::episode")" -gt "$lastEpisode" ]; then
        lastEpisode="$(serenity.tokens.get "$e::episode")"
      fi
      if [ "$(serenity.tokens.get "$e::episode")" -lt "$firstEpisode" ]; then
        firstEpisode="$(serenity.tokens.get "$e::episode")"
      fi
    done
    if [[ -n "$(serenity.tokens.get -n common::show)" ]] && [[ -n "$(serenity.tokens.get -n common::season)" ]]; then
      serenity.debug.debug "Summarize: range episode mode"
      serenity.tokens.set first_episode "$firstEpisode"
      serenity.tokens.set last_episode "$lastEpisode"
      local commonTitle="$(serenity.processing.stripTitle "${titles[0]}")"
      local sameTitle=true
      for e in "${titles[@]:1}"; do
        [ "$commonTitle" != "$(serenity.processing.stripTitle "${e}")" ] &&
        sameTitle=false &&
        break
      done
      $sameTitle && serenity.tokens.set common::title "$commonTitle"
    fi
  fi
  serenity.tokens.serialize
}

# Token formatting
serenity.processing.formatting() {
  # Tokens deserialization
  local -A serenity__currentTokens=()
  serenity.tokens.deserialize

  "serenity.formatters.${@}"
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
