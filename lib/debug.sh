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

readonly serenity_debug_debug=10
readonly serenity_debug_info=20
readonly serenity_debug_warning=30
readonly serenity_debug_error=40
readonly serenity_debug_critical=50
readonly serenity_debug_quiet=99

serenity.debug.echostderr() {
  echo "$@" >&2
}

serenity.debug.debug() {
  (( "$serenity_conf_verbosity" <= "$serenity_debug_debug" )) &&
  serenity.debug.echostderr "[DEBUG] $@"
  true
}

serenity.debug.info() {
  (( "$serenity_conf_verbosity" <= "$serenity_debug_info" )) &&
  serenity.debug.echostderr "[INFO] $@"
  true
}

serenity.debug.warning() {
  (( "$serenity_conf_verbosity" <= "$serenity_debug_warning" )) &&
  serenity.debug.echostderr "[WARNING] $@"
  true
}

serenity.debug.error() {
  (( "$serenity_conf_verbosity" <= "$serenity_debug_error" )) &&
  serenity.debug.echostderr "[ERROR] $@"
  true
}

serenity.debug.critical() {
  (( "$serenity_conf_verbosity" <= "$serenity_debug_critical" )) &&
  serenity.debug.echostderr "[CRITICAL] $@"
  true
}
