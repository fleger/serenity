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

local serenity_conf_datasource_csv_file="serenity.csv"
local serenity_conf_datasource_csv_separator=";"
local -a serenity_conf_datasource_csv_format=()

serenity.datasources.csv.run() {
  if [ -f "$serenity_conf_datasource_csv_file" ]; then
    serenity.debug.debug "CSV: reading $serenity_conf_datasource_csv_file"
    local line
    local token
    local counter=0
    local -A items
    local -a header=()
    local state=HEADER
    while IFS= read line; do
      case "$state" in
        HEADER)
          while read -d "$serenity_conf_datasource_csv_separator" token; do
            serenity.debug.debug "CSV: reading token type $token"
            header+=("$token")
          done <<< "$line$serenity_conf_datasource_csv_separator" # Hack: add separator at the end of the line
          state=BODY
          ;;
        BODY)
          counter=0
          items=()
          serenity.debug.debug "CSV: reading line $line"
          while read -d "$serenity_conf_datasource_csv_separator" token; do
            serenity.debug.debug "CSV: reading token $token"
            items[${header[$counter]}]="$token"
            counter=$(($counter + 1))
          done <<< "$line$serenity_conf_datasource_csv_separator" # Hack: add separator at the end of the line
          [ "x${items[season]}" = "x$(serenity.tokens.get season)" ] &&
          [ "x${items[episode]}" = "x$(serenity.tokens.get episode)" ] && {
            serenity.debug.debug "CSV: line matches season and episode"
            local key
            for key in "${!items[@]}"; do
              serenity.tokens.set "${key}" "${items["${key}"]}"
            done
            return 0
          }
          ;;
      esac
    done < "$serenity_conf_datasource_csv_file"
  else
    serenity.debug.debug "CSV: $serenity_conf_datasource_csv_file doesn't exist"
  fi
  return 1
}
