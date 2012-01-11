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

local -r serenity_debug_debug=10
local -r serenity_debug_info=20
local -r serenity_debug_warning=30
local -r serenity_debug_error=40
local -r serenity_debug_critical=50
local -r serenity_debug_quiet=99

serenity.debug.echostderr() {
  local prefix="$1"
  shift
  local OLD_IFS="$IFS"
  IFS=$'\n'
  for l in $@; do
    echo "$prefix$l" >&2
  done
  IFS="$OLD_IFS"
}

serenity.debug.debug() {
  (( "$serenity_conf_verbosity" <= "$serenity_debug_debug" )) &&
  serenity.debug.echostderr "[DEBUG] " "$@"
  true
}

serenity.debug.info() {
  (( "$serenity_conf_verbosity" <= "$serenity_debug_info" )) &&
  serenity.debug.echostderr "[INFO] " "$@"
  true
}

serenity.debug.warning() {
  (( "$serenity_conf_verbosity" <= "$serenity_debug_warning" )) &&
  serenity.debug.echostderr "[WARNING] " "$@"
  true
}

serenity.debug.error() {
  (( "$serenity_conf_verbosity" <= "$serenity_debug_error" )) &&
  serenity.debug.echostderr "[ERROR] " "$@"
  true
}

serenity.debug.critical() {
  (( "$serenity_conf_verbosity" <= "$serenity_debug_critical" )) &&
  serenity.debug.echostderr "[CRITICAL] " "$@"
  true
}
