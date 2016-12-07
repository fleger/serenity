#    serenity - An automated episode renamer.
#    Copyright (C) 2010-2016  Florian Léger
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

# TVMaze SingleSearch data source

# TODO: cache responses per show, reuse TheTVDB idl cache for queries 

serenity.datasources.tvmaze:() {
  local -r serenity_datasources_tvmaze_requestFormat="http://api.tvmaze.com/singlesearch/shows?q=%s&embed=episodes"
  local -ar serenity_datasources_tvmaze_fieldTypes=(show)
  local -Ar serenity_datasources_tvmaze_jqExtractors=(
    [show]='.name'
    [title]='._embedded.episodes[] | select(.number == %episode% and .season == %season%).name'
    [premiered]='.premiered?'
    [date]='._embedded.episodes[] | select(.number == %episode% and .season == %season%).airdate?'
    [country]='.network?.country?.code?'
    [status]='.status'
    [classification]='.type'
    [genres]='.genres | join(",")'
    [network]='.network?.name?'
    [runtime]='._embedded.episodes[] | select(.number == %episode% and .season == %season%).runtime?'
  )

  "$@"
}

serenity.datasources.tvmaze.run() {
  local -a fields=()
  local tokenType=""
  local request=""

  for tokenType in "${serenity_datasources_tvmaze_fieldTypes[@]}"; do
    fields+=("$(serenity.filters.urlEncode < <(serenity.tokens.get "${tokenType}"))")
  done

  request="$(printf "${serenity_datasources_tvmaze_requestFormat}" "${fields[@]}")" &&
  serenity.debug.debug "TVMaze: generated request: $request" || {
    serenity.debug.warning "TVMaze: failed to generate request ${serenity_datasources_tvmaze_requestFormat} ${fields[*]}"
    return 1
  }

  local response
  response="$(curl -s --connect-timeout "${serenity_conf_curl_connectTimeout}" --retry "${serenity_conf_curl_retry}" "${request}")" && {
    if grep '&#[0-9]*;' <<< "${response}"> /dev/null ; then
      response="$(asc2xml <<< "${response}")"
    fi
    serenity.debug.debug "TVMaze: begin response"
    serenity.debug.debug "$response"
    serenity.debug.debug "TVMaze: end response"
  } || {
    serenity.debug.warning "TVMaze: request failure"
    return 1
  }

  for tokenType in "${!serenity_datasources_tvmaze_jqExtractors[@]}"; do
    local expression="${serenity_datasources_tvmaze_jqExtractors["${tokenType}"]}"
    expression="${expression//%episode%/$(serenity.tokens.get "episode")}"
    expression="${expression//%season%/$(serenity.tokens.get "season")}"
    serenity.debug.debug "TVMaze using expression ${expression} for $tokenType"
    serenity.tokens.set "${tokenType}" "$(jq -cr "${expression}" <<< "${response}")"
  done
}
