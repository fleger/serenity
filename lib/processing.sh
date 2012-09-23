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

# Processing algorithms

# serenity.processing.callFilterChain CHAIN
#
# Call the given filter CHAIN
serenity.processing.callFilterChain() {
  if [[ -n "${1}" ]]; then
    serenity.pipeline: "serenity.conf.chains.${1}"
  else
    echo "$(< /dev/stdin)"
  fi
}

# serenity.processing.callFilterChainOnToken CHAIN TOKEN
#
# Call the given filter CHAIN on TOKEN
#
# Closures: serenity.tokens:
serenity.processing.callFilterChainOnToken() {
  serenity.tokens.set "$2" "$(serenity.processing.callFilterChain "$1" < <(serenity.tokens.get "$2"))"
}

# serenity.processing.tokenization INPUT_TOKEN
#
# Extract tokens from INPUT_TOKEN.
#
# Closures: serenity.main, serenity.tokens:
serenity.processing.tokenization() {
  local inputBuffer="$(serenity.tokens.get "$1")"
  local offset=0
  local length
  local -a commandLine=()

  # Strip extension
  if [[ "x$serenity_conf_keepExtension" = "xyes" ]]; then
    local extension=""
    [[ "${inputBuffer}" =~ ^.*\..*$ ]] && extension=".${inputBuffer##*.}"
    inputBuffer="${inputBuffer%.*}"
  fi

  for length in "${serenity_conf__tokenizerLengths[@]}"; do
    commandLine=("${serenity_conf__tokenizers[@]:${offset}:${length}}")
    offset=$(( ${offset} + ${length} ))
    commandLine[0]="serenity.tokenizers.${commandLine[0]}.run"
    if serenity.tokens.nested: serenity.tokens- "${commandLine[@]}" <<< "${inputBuffer}"; then
      serenity.debug.debug "Tokenization: success with ${commandLine[*]}"
      if [ "x$serenity_conf_keepExtension" = "xyes" ]; then
        serenity.tokens.set "_::extension" "$extension"
      fi
     return 0
    else
      serenity.debug.debug "Tokenization: failure with ${commandLine[*]}"
    fi
  done
  serenity.debug.error "Tokenization: file name can't be tokenized"
  return 1
}


# serenity.processing.split
#
# Run the splitters.
#
# Closures: serenity.main, serenity.tokens:
serenity.processing.split() {
  local i
  local returnCode=1
  for i in "${serenity_conf_splitterPriorities[@]}"; do
    if serenity.splitters."$i".checkRequirements; then
      serenity.debug.debug "Split: running $i splitter"
      serenity.splitters."$i".run "$@"
      serenity.tokens.set "_::splitter" "$i"
      returnCode=0
      break
    fi
  done

  return "$returnCode"
}


# serenity.processing.tokenProcessing [TOKEN_TYPE FILTER_CHAIN]...
#
# Process the tokens with filter chains.
#
# Closure: serenity.tokens:
serenity.processing.tokenProcessing() {
  # Processing chains unpacking
  local -A tokenProcessing=()
  until [[ "$#" -lt 2 ]]; do
    tokenProcessing["${1}"]="${2}"
    shift 2
  done

  local -A processedTokens=()

  # Processing
  local tokenType
  # FIXME: private API violation
  for tokenType in "${!tokens_current[@]}"; do
    if [[ "$tokenType" != _::* ]]; then
      if serenity.tools.contains "${tokenType#*::}" "${!tokenProcessing[@]}"; then
        processedTokens["${tokenType}"]="$(serenity.processing.callFilterChain "${tokenProcessing["${tokenType#*::}"]}" < <(serenity.tokens.get "${tokenType}"))"
      else
        processedTokens["${tokenType}"]="$(serenity.processing.callFilterChain "${tokenProcessing["default"]}" < <(serenity.tokens.get "${tokenType}"))"
      fi
    fi
    # TODO: process explicitely prefixed tokens
  done

  # Merging
  for tokenType in "${!processedTokens[@]}"; do
    serenity.tokens.set "${tokenType}" "${processedTokens["$tokenType"]}"
  done
}

serenity.processing.enableDatasources:() {
  local commandLine=()
  while [[ "$1" != "--" ]]; do
    serenity.tools.isFunction "serenity.datasources.${1}:" &&
    commandLine+=("serenity.datasources.${1}:")
    shift
  done
  shift
  "${commandLine[@]}" "$@"
}


# serenity.processing.queryDatasource DATASOURCE...
#
# Refine the tokens using the first DATASOURCE that succeed.
#
# Closure: serenity.tokens:
serenity.processing.queryDatasources() {
  local datasource
  for datasource; do
    serenity.tokens.nested: serenity.tokens- "serenity.datasources.${datasource}.run" &&
    serenity.debug.debug "Refining: success with ${datasource}" &&
    serenity.tokens.set "_::datasource" "${datasource}" &&
    return 0 ||
    serenity.debug.debug "Refining: failure with ${datasource}"
  done
  return 1
}

# serenity.processing.aggregate AGGREGATOR...
#
# Aggregate the tokens using the first AGGREGATOR that succeed.
#
# Closure: serenity.tokens:
serenity.processing.aggregate() {
  local i
  for i; do
    if serenity.aggregators."$i".checkRequirements; then
      serenity.debug.debug "Aggregator: running $i aggregator"
      serenity.aggregators."$i".run
    fi
  done
}

# serenity.processing.format OUTPUT_TOKEN FORMATTER [ARG]...
#
# Format the tokens to produce the final name.
#
# Closure: serenity.tokens:
serenity.processing.format() {
  local outputTokenType="$1"
  shift
  # Note: Shouldn't this be "${@:1}"?
  serenity.tokens.set "$outputTokenType" "$("serenity.formatters.${1}.run" "${@:2}")"
}
