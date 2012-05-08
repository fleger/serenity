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

# Core algorithms

# Call a given filter chain
serenity.core.callFilterChain() {
  if [ "x${1}" != "x" ]; then
    serenity.pipeline.execute "serenity.conf.chains.${1}"
  else
    echo "$(< /dev/stdin)"
  fi
}

# Tokenization (with token environment)
serenity.core.tokenization() {
  local inputBuffer="$(< /dev/stdin)"
  local offset=0
  local length
  local -a commandLine=()

  if [ "x$serenity_conf_keepExtension" = "xyes" ]; then
    local extension=""
    [[ "${inputBuffer}" =~ ^.*\..*$ ]] && extension=".${inputBuffer##*.}"
    inputBuffer="${inputBuffer%.*}"
  fi

  for length in "${serenity_conf__tokenizerLengths[@]}"; do
    commandLine=("${serenity_conf__tokenizers[@]:${offset}:${length}}")
    offset=$(( ${offset} + ${length} ))
    commandLine[0]="serenity.tokenizers.${commandLine[0]}.run"
    local -A serenity__currentTokens=()
    if "${commandLine[@]}" <<< "${inputBuffer}"; then
      serenity.debug.debug "Tokenization: success with ${commandLine[*]}"
      if [ "x$serenity_conf_keepExtension" = "xyes" ]; then
        serenity.tokens.set "_::extension" "$extension"
      fi
      # Token serialization
      serenity.tokens.serialize &&
      return 0
    else
      serenity.debug.debug "Tokenization: failure with ${commandLine[*]}"
    fi
  done
  serenity.debug.error "Tokenization: file name can't be tokenized"
  return 1
}

serenity.core.split() {
  # Tokens deserialization
  local -A serenity__currentTokens=()
  serenity.tokens.deserialize

  local i
  local returnCode=1
  for i in "${serenity_conf_splitterPriorities[@]}"; do
    if serenity.splitters."$i".checkRequirements; then
      serenity.debug.debug "Split: running $i splitter"
      serenity.splitters."$i".run "$@"
      returnCode=0
      break
    fi
  done

  return "$returnCode"
}

# Token processing (with token environment)
serenity.core.tokenProcessing() {
  # Processing chains unpacking
  local -A tokenProcessing=()
  until [[ "$#" -lt 2 ]]; do
    tokenProcessing["${1}"]="${2}"
    shift 2
  done

  # Token deserialization
  local -A serenity__currentTokens=()
  serenity.tokens.deserialize

  local -A processedTokens=()

  # Processing
  local tokenType
  for tokenType in "${!serenity__currentTokens[@]}"; do
    if [[ "$tokenType" != _::* ]]; then
      if serenity.tools.contains "${tokenType#*::}" "${!tokenProcessing[@]}"; then
        processedTokens["${tokenType}"]="$(serenity.core.callFilterChain "${tokenProcessing["${tokenType#*::}"]}" < <(serenity.tokens.get "${tokenType}"))"
      else
        processedTokens["${tokenType}"]="$(serenity.core.callFilterChain "${tokenProcessing["default"]}" < <(serenity.tokens.get "${tokenType}"))"
      fi
    fi
  done

  # Merging
  for tokenType in "${!processedTokens[@]}"; do
    serenity.tokens.set "${tokenType}" "${processedTokens["$tokenType"]}"
  done

  # Token serialization
  serenity.tokens.serialize
}

# Token refining
serenity.core.refining() {
  # Tokens deserialization
  local -A serenity__currentTokens=()
  serenity.tokens.deserialize

  local backend
  for backend; do
    "serenity.refiningBackends.${backend}.run" &&
    serenity.debug.debug "Refining: success with ${backend}" &&
    serenity.tokens.set "_::refining_backend" "${backend}" &&
    # Token serialization
    serenity.tokens.serialize &&
    return 0 ||
    serenity.debug.debug "Refining: failure with ${backend}"
  done
  return 1
}

serenity.core.aggregate() {
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
serenity.core.formatting() {
  # Tokens deserialization
  local -A serenity__currentTokens=()
  serenity.tokens.deserialize
  # Note: Shouldn't this be "${@:1}"?
  "serenity.formatters.${1}.run" "${@:2}"
}
