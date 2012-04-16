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
#    along with this program.  If not, see <http://www.gnu.org/licenses/>

serenity.aggregators.multi.checkRequirements() {
  [[ "$(serenity.tokens.get "_::episode_count")" -gt "1" ]]
}

serenity.aggregators.multi.run() {
  # Multiple episodes
  local e
  serenity.tokens.copyCommon common $(seq 1 "$(serenity.tokens.get "_::episode_count")")
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
    serenity.debug.debug "Multi aggregator: common show & season"
    serenity.tokens.set first_episode "$firstEpisode"
    serenity.tokens.set last_episode "$lastEpisode"
    local commonTitle="$(serenity.aggregators.multi.stripTitle "${titles[0]}")"
    local sameTitle=true
    for e in "${titles[@]:1}"; do
      [ "$commonTitle" != "$(serenity.aggregators.multi.stripTitle "${e}")" ] &&
      sameTitle=false &&
      break
    done
    $sameTitle && serenity.tokens.set common::title "$commonTitle"
  fi
}

serenity.aggregators.multi.stripTitle() {
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
