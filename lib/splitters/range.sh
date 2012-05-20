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

serenity.splitters.range.checkRequirements() {
  [[ -n "$(serenity.tokens.get first_episode)" ]] && [[ -n "$(serenity.tokens.get last_episode)" ]]
}

serenity.splitters.range.run() {
  local i=0
  local n
  for n in $(seq "$(serenity.tokens.get first_episode)" "$(serenity.tokens.get last_episode)"); do
    i=$(( $i + 1 ))
    serenity.tokens.set episode "${n}"
    serenity.tokens.serialize | "${@}" | serenity.tokens.execute serenity.tokens.copyPrefix "" "$i"
  done
  serenity.tokens.addToStream "_::episode_count" "$i"
}
