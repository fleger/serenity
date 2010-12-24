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

readonly serenity_backends_tvrage_REQUEST_PATTERN="http://services.tvrage.com/tools/quickinfo.php?show=%SHOW_NAME%&ep=%SEASON_NB%x%EPISODE_NB%"

serenity.backends.tvrage.extractShowName() {
  local r &&
  r="""$(echo "$1" | grep "^Show Name@")""" &&
  echo "$r" | sed -e "s/^Show Name@//"
}

serenity.backends.tvrage.extractEpisodeName() {
  local r &&
  r="""$(echo "${1}" | grep "^Episode Info@")""" &&
  echo "${r}" | cut --delimiter="^" --fields=2
}

serenity.backends.tvrage() {
  serenity.debug.debug "Trying TVRage backend"
  local showName="""$(serenity.tools.urlEncode "${1}")""" &&
  local seasonNb="""$(serenity.tools.urlEncode "${2}")""" &&
  local episodeNb="""$(serenity.tools.urlEncode "${3}")""" &&
  local request &&
  request="""$(echo "${serenity_backends_tvrage_REQUEST_PATTERN}" | sed -e "s/%SHOW_NAME%/$showName/;s/%SEASON_NB%/$seasonNb/;s/%EPISODE_NB%/$episodeNb/")""" &&
  serenity.debug.debug "TVRage request:" &&
  serenity.debug.debug $request &&
  local response &&
  response="""$(curl -s "${request}")""" &&
  serenity.debug.debug "TVRage response:" &&
  serenity.debug.debug $response &&
  echo """$(serenity.backends.tvrage.extractShowName "${response}")""" &&
  echo "${2}" &&
  echo "${3}" &&
  echo """$(serenity.backends.tvrage.extractEpisodeName "${response}")"""
}

