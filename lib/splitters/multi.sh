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

serenity.splitters.multi.checkRequirements() {
  [[ -n "$(serenity.tokens.get 1::episode)" ]]
}

serenity.splitters.multi.definition() {
  local -i prefix="$1"
  shift
  serenity.tokens.movePrefix "$prefix" ""
  "$@"
  serenity.tokens.add serenity.tokens.movePrefix "" "$prefix"
}

serenity.splitters.multi.run() {
  local -i i=1
  while [[ -n "$(serenity.tokens.get ${i}::episode)" ]]; do
    serenity.tokens.nestedExecute serenity.splitters.multi.definition "${i}" "${@}"
    i=$(( i + 1 ))
  done
  i=$(( i - 1 ))
  serenity.tokens.set "_::episode_count" "$i"
}
