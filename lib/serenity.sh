#    serenity - An automated episode renamer.
#    Copyright (C) 2010  Florian Léger
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

shopt -s extglob

. ${serenity_env_lib}/debug.sh || exit 1

serenity.crash() {
  serenity.debug.critical "$@"
  exit 1
}

. ${serenity_env_lib}/nakedconf.sh || serenity.crash "Failed to load ${serenity_env_lib}/nakedconf.sh"
. ${serenity_env_lib}/tools.sh || serenity.crash "Failed to load ${serenity_env_lib}/tools.sh"

serenity.loadConfig() {
  local -a loadedFiles
  local f
  local i
  local alreadyLoaded
  for f in "${serenity_env_conf[@]}"; do
    serenity.debug.debug "Trying to load $f" &&
    [ -f "$f" ] &&
    serenity.debug.debug "$f is a file" &&
    alreadyLoaded=false &&
    f="$(readlink -f ${f})" &&
    for i in "${loadedFiles[@]}"; do
      [[ "${i}" == "${f}" ]] &&
      alreadyLoaded=true &&
      serenity.debug.debug "$f is alreadyLoaded"
    done &&
    ! $alreadyLoaded &&
    loadedFiles+=("${f}") &&
    serenity.debug.debug "Loading configuration file $f" &&
    . "${f}"
  done
}

serenity.loadBackends() {
  local f
  for f in ${serenity_env_lib}/backends/*.sh; do
    [ -f ${f} ] &&
    serenity.debug.debug "Loading backend $f" &&
    . ${f}
  done
}

serenity.steps.preprocessing() {
  # URL decode the filename
  local arg="$(serenity.tools.urlDecode ${1})" &&
  local sedLine=() &&
  local pp &&
  for pp in "${serenity_conf_preprocessing[@]}"; do
    sedLine+=(-e) &&
    sedLine+=(${pp})
  done &&
  echo ${arg} | sed -r "${sedLine[@]}"
}

serenity.steps.tokenizing() {
  local i  &&
  for i in "${!serenity_conf_tokenizers_regex[@]}"; do
    local -A results &&
    [[ $1 =~ ${serenity_conf_tokenizers_regex[$i]} ]] &&
    results["${serenity_conf_tokenizers_associations:0:1}"]="${BASH_REMATCH[1]}" &&
    results["${serenity_conf_tokenizers_associations:1:1}"]="${BASH_REMATCH[2]}" &&
    results["${serenity_conf_tokenizers_associations:2:1}"]="${BASH_REMATCH[3]}" &&
    printf "%s\n%s\n%s\n" "${results[t]}" "${results[s]/#*(0)/}" "${results[e]/#*(0)/}" &&
    return 0
  done
  return 1
}

serenity.steps.refining() {
  local backend &&
  for backend in "${serenity_conf_backends[@]}"; do
    serenity.backends.$backend $@ &&
    serenity.debug.debug "Refinement successful" &&
    return 0
  done
  return 1
}

serenity.steps.postprocessing() {
  local sedLine=() &&
  local pp &&
  for pp in "${serenity_conf_postprocessing[@]}"; do
    sedLine+=(-e) &&
    sedLine+=(${pp})
  done
  sedLine+=(-e)  &&
  sedLine+=('s/[/\]/-/g') &&                # Force substitution of slashes / backslashes
  for arg; do
    echo ${arg} | sed -r "${sedLine[@]}"
  done
}

serenity.steps.formatting() {
  local -A associations &&
  local fields=() &&
  local c &&

  associations[t]=${1} &&
  associations[s]=${2/#*(0)/} &&
  associations[e]=${3/#*(0)/} &&
  associations[n]=${4} &&

  for c in $(serenity.tools.characters ${serenity_conf_formatting_associations}); do
    fields+=(${associations[${c}]})
  done &&

  printf "$serenity_conf_formatting_format" "${fields[@]}"
}

serenity.steps.extension() {
  local ext=""
  [[ ${2} =~ ^.*\..*$ ]] && ext=.${2##*.}
  echo ${1}${ext}
}

serenity.steps.move() {
  mkdir -p "$(dirname ${2})" &&
  mv ${serenity_conf_mv_args[@]} ${1} ${2}
}

serenity.steps() {
  local preProcessedName &&
  local rawTokens &&
  local refinedTokens &&
  local postProcessedTokens &&
  local formattedName &&
  local finalName &&
  local fileName="$(basename ${1})" &&

  preProcessedName="$(serenity.steps.preprocessing ${fileName})" &&
  serenity.debug.debug "Pre-processed filename: $preProcessedName" &&
  rawTokens="$(serenity.steps.tokenizing ${preProcessedName})" &&
  serenity.debug.debug "Raw tokens: " $rawTokens &&
  refinedTokens="$(serenity.steps.refining $rawTokens)" &&
  serenity.debug.debug "Refined tokens: " $refinedTokens &&
  postProcessedTokens="$(serenity.steps.postprocessing $refinedTokens)" &&
  serenity.debug.debug "Post-processed tokens: " $postProcessedTokens &&
  formattedName="$(serenity.steps.formatting $postProcessedTokens)" &&
  serenity.debug.debug "Formatted name: " $formattedName &&
  finalName="$(serenity.steps.extension ${formattedName} ${fileName})" &&
  serenity.debug.debug "Final name: " $finalName &&
  if [ ! ${serenity_conf_dry_run} ]; then
    serenity.steps.move ${1} "$(readlink -f ${serenity_conf_output_prefix})/${finalName}"
  else
    echo ${finalName}
  fi
}

serenity.showHelp() {
  cat << EOF
Usage: ${serenity_env_executable} [OPTION...] FILE...

Options and arguments:

  -d              dry-run; don't rename files, only print their new name
  -l <string>     list parameter values and exit:
                      - preprocessing, tokenizers, backends, postprocessing, formatting
  -o <string>     set output prefix [default: none]
  -f              do not prompt before overwriting
  -i              prompt before overwrite
  -b              backup each existing destination file
  -n              do not overwrite an existing file
  -h              show help and exit

EOF
    return 1
}

serenity.run() {
  local f
  for f; do
    serenity.steps ${f} || return 1
  done
}

serenity.list() {
  local i
  case ${serenity_conf_list} in
    "preprocessing")
      for i in "${serenity_conf_preprocessing[@]}"; do
        echo ${i}
      done;;
    "postprocessing")
      for i in "${serenity_conf_postprocessing[@]}"; do
        echo ${i}
      done;;
    "tokenizers")
      for i in "${!serenity_conf_tokenizers_regex[@]}"; do
        echo "${serenity_conf_tokenizers_regex[$i]}"
        echo "${serenity_conf_tokenizers_associations[$i]}"
      done;;
    "backends")
      for i in "${serenity_conf_backends[@]}"; do
        echo ${i}
      done;;
    "formatting")
      echo ${serenity_conf_formatting_format}
      echo ${serenity_conf_formatting_associations};;
    *)
      echo "${serenity_conf_list} is not a valid parameter." >&2
      return 1;;
  esac
}

serenity.main() {
  serenity.loadConfig
  serenity.loadBackends
  local -A actions
  actions["run"]=serenity.run
  actions["help"]=serenity.showHelp
  actions["list"]=serenity.list
  local opt
  local action="run"

  while getopts dl:o:fibnh opt; do
    case "$opt" in
      d) serenity_conf_dry_run="0";;
      l)
        serenity_conf_list=${OPTARG}
        action="list";;
      o) serenity_conf_output_prefix="$OPTARG";;
      f) serenity_conf_mv_args+=(-f);;
      i) serenity_conf_mv_args+=(-i);;
      b) serenity_conf_mv_args+=(-b);;
      n) serenity_conf_mv_args+=(-n);;
      h|?) action="help";;
    esac
  done
  shift $(($OPTIND - 1))
  (($# < 1)) && [ "$action" = "run" ] && action="help"

  local OLD_IFS=${IFS}
  IFS=$'\n'
  ${actions[$action]} ${@}
  local errorCode=$?
  IFS=${OLD_IFS}
  return $errorCode
}
