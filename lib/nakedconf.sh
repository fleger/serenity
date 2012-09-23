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

# Serenity naked configuration file

local -a serenity_conf__tokenizers=()
local -a serenity_conf__tokenizerLengths=()

serenity.conf.addTokenizer() {
  if [ "$#" -gt 0 ]; then
    serenity_conf__tokenizerLengths+=("${#}")
    serenity_conf__tokenizers+=("${@}")
  else
    serenity.debug.error "serenity.conf.addTokenizer: missing arguments"
    return 1
  fi
}

serenity.conf.check.run() {
  local i
  for i in $(compgen -A function "serenity.conf.check.list."); do
    "$i" && {
      serenity.debug.debug "Check: ${i#serenity.conf.check.list.} OK"
    } || {
      serenity.crash "Check: ${i#serenity.conf.check.list.} KO"
    }
  done
}

# $1: array
# $2: function prefix
# $3: function suffix
serenity.conf.check.functions() {
  # Parse command line
  local opt
  local OPTARG
  local OPTIND=1
  local allowEmpty=false
  while getopts e opt; do
    case "$opt" in
      e) allowEmpty=true;;
    esac
  done
  shift $((${OPTIND} - 1))

  local i
  local ref="$1[@]"

  for i in "${!ref}"; do
    { $allowEmpty && [[ -z "$i" ]]; } || serenity.tools.isFunction "$2$i$3" || {
      serenity.debug.error "Function check: $i specified in $1 is not valid"
      return 1
    }
  done
}

# $1: variable to test
serenity.conf.check.yesNo() {
  [[ "${!1}" == "yes" || "${!1}" == "no" ]] || {
    serenity.debug.error "Yes/No check: ${1} must be yes or no"
    return 1
  }
}

serenity.conf.check.list.globalPreprocessing() {
  serenity.conf.check.functions -e "serenity_conf_globalPreprocessing" "serenity.conf.chains."
}

serenity.conf.check.list.tokenPreprocessing() {
  serenity.conf.check.functions -e "serenity_conf_tokenPreprocessing" "serenity.conf.chains."
}

serenity.conf.check.list.tokenPostprocessing() {
  serenity.conf.check.functions -e "serenity_conf_tokenPostprocessing" "serenity.conf.chains."
}

serenity.conf.check.list.globalPostprocessing() {
  serenity.conf.check.functions -e "serenity_conf_globalPostprocessing" "serenity.conf.chains."
}

serenity.conf.check.list.splitters() {
  serenity.conf.check.functions "serenity_conf_splitterPriorities" "serenity.splitters." ".run" || return 1
  serenity.conf.check.functions "serenity_conf_splitterPriorities" "serenity.splitters." ".checkRequirements" || return 1
}

serenity.conf.check.list.datasources() {
  serenity.conf.check.functions "serenity_conf_datasources" "serenity.datasources." ".run"
}

serenity.conf.check.list.aggregators() {
  serenity.conf.check.functions "serenity_conf_aggregatorPriorities" "serenity.aggregators." ".run" || return 1
  serenity.conf.check.functions "serenity_conf_aggregatorPriorities" "serenity.aggregators." ".checkRequirements" || return 1
}

serenity.conf.check.list.tokenizers() {
  local length=0
  local offset=0
  local name=""
  for length in "${serenity_conf__tokenizerLengths[@]}"; do
    name="${serenity_conf__tokenizers[@]:${offset}:1}"
    offset=$(( ${offset} + ${length} ))
    serenity.tools.isFunction "serenity.tokenizers.$name.run" || {
      serenity.debug.error "Tokenizer check: $name is not valid"
      return 1
    }
  done
}

serenity.conf.check.list.formatter() {
  serenity.tools.isFunction "serenity.formatters.${serenity_conf_formatting[0]}.run" || {
    serenity.debug.error "Formatter check: ${serenity_conf_formatting[0]} is not valid"
    return 1
  }
}

serenity.conf.check.list.tracing() {
  serenity.conf.check.yesNo serenity_conf_tracing
}

serenity.conf.check.list.keepExtension() {
  serenity.conf.check.yesNo serenity_conf_keepExtension
}

local serenity_conf_globalPreprocessing=''
local -A serenity_conf_tokenDefaults=()
local -A serenity_conf_tokenPreprocessing=()
local -a serenity_conf_splitterPriorities=()
local -a serenity_conf_refiningBackends=('dummy')
local -a serenity_conf_aggregatorPriorities=()
local -A serenity_conf_tokenPostprocessing=()
local -a serenity_conf_formatting=()
local serenity_conf_globalPostprocessing=''
local serenity_conf_tracing='no'
local serenity_conf_keepExtension='yes'
local -a serenity_conf_multipartStripList=()

