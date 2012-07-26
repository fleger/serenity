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

# TVRage QuickInfo refining backend

serenity.refiningBackends.tvrage.context() {
  local -r serenity_refiningBackends_tvrage_requestFormat="http://services.tvrage.com/tools/quickinfo.php?show=%s&ep=%dx%d"
  local -ar serenity_refiningBackends_tvrage_fieldTypes=(show season episode)
  local -Ar serenity_refiningBackends_tvrage_sedExtractors=([show]='s/^Show Name@(.+)$/\1/p'
    [title]='s/^Episode Info@[0-9]+x[0-9]+\^([^\^]+)\^.*$/\1/p'
    [premiered]='s/^Premiered@([0-9]+)$/\1/p'
    [started]='s/^Started@(.+)$/\1/p'
    [ended]='s/^Ended@(.+)$/\1/p'
    [date]='s/^Episode Info@[0-9]+x[0-9]+\^[^\^]+\^(.+)$/\1/p'
    [country]='s/^Country@(.+)$/\1/p'
    [status]='s/^Status@(.+)$/\1/p'
    [classification]='s/^Classification@(.+)$/\1/p'
    [genres]='s/^Genres@(.+)$/\1/p'
    [network]='s/^Network@(.+)$/\1/p'
    [runtime]='s/^Runtime@([0-9]+)$/\1/p')

  "$@"
}

serenity.refiningBackends.tvrage.run() {
  local -a fields=()
  local tokenType=""
  local request=""

  for tokenType in "${serenity_refiningBackends_tvrage_fieldTypes[@]}"; do
    fields+=("$(serenity.filters.urlEncode < <(serenity.tokens.get "${tokenType}"))")
  done

  request="$(printf "${serenity_refiningBackends_tvrage_requestFormat}" "${fields[@]}")" &&
  serenity.debug.debug "TVRage: generated request: $request" || {
    serenity.debug.warning "TVRage: failed to generate request ${serenity_refiningBackends_tvrage_requestFormat} ${fields[*]}"
    return 1
  }

  local response
  response="$(curl -s "${request}")" && {
    if grep '&#[0-9]*;' <<< "${response}"> /dev/null ; then
      response="$(asc2xml <<< "${response}")"
    fi
    serenity.debug.debug "TVRage: begin response"
    serenity.debug.debug "$response"
    serenity.debug.debug "TVRage: end response"
  } || {
    serenity.debug.warning "TVRage: request failure"
    return 1
  }

  for tokenType in "${!serenity_refiningBackends_tvrage_sedExtractors[@]}"; do
    serenity.debug.debug "TVRage: using expression ${serenity_refiningBackends_tvrage_sedExtractors["${tokenType}"]} for $tokenType"
    serenity.tokens.set "${tokenType}" "$(sed -n -r -e "${serenity_refiningBackends_tvrage_sedExtractors["${tokenType}"]}" <<< "${response}")"
  done
}
