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

serenity.backends.csv() {
  serenity.debug.debug "Trying CSV backend"
  if [ -f "$serenity_conf_backend_csv_file" ]; then
    serenity.debug.debug "CSV: Reading $serenity_conf_backend_csv_file"
    local line
    local token
    local counter
    local -A items
    while read line; do
      counter=0
      items=()
      serenity.debug.debug "CSV: Reading line $line"
      while read -d "$serenity_conf_backend_csv_separator" token; do
        serenity.debug.debug "CSV: Reading token $token"
        items[${serenity_conf_backend_csv_format[$counter]}]="$token"
        counter=$(($counter + 1))
      done < <(echo "$line$serenity_conf_backend_csv_separator") # Hack: add separator at the end of the line
      [ "x${items[season]}" = "x$2" ] &&
      [ "x${items[episode]}" = "x$3" ] &&
      echo ${items[show]} &&
      echo ${items[season]} &&
      echo ${items[episode]} &&
      echo ${items[title]} &&
      return 0
    done < "$serenity_conf_backend_csv_file"
  else
    serenity.debug.debug "CSV: $serenity_conf_backend_csv_file doesn't exist"
  fi
  return 1
}
