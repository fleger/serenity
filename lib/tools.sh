#    serenity - An automated episode renamer.
#    Copyright (C) 2010-2011  Florian Léger
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

readonly serenity_tools_roman_numeral_regex="[IVXLCDMivxlcdm]+"

serenity.tools.urlEncode() {
  local arg="$1"
  while [[ "$arg" =~ ^([0-9a-zA-Z/:_\.\-]*)([^0-9a-zA-Z/:_\.\-])(.*) ]]; do
    echo -n "${BASH_REMATCH[1]}"
    printf "%%%X" "'${BASH_REMATCH[2]}'"
    arg="${BASH_REMATCH[3]}"
  done
  # the remaining part
  echo -n "$arg"
}

serenity.tools.urlDecode() {
  local arg="$1"
  local i="0"
  while [ "$i" -lt ${#arg} ]; do
    local c0=${arg:$i:1}
    if [ "x$c0" = "x%" ]; then
      local c1=${arg:$((i+1)):1}
      local c2=${arg:$((i+2)):1}
      printf "\x$c1$c2"
      i=$((i+3))
    else
      echo -n "$c0"
      i=$((i+1))
    fi
  done
}

serenity.tools.characters() {
  local arg="$1"
  local i=-1
  while (( ++i < ${#arg} )); do
    echo "${arg:$i:1}"
  done
}

serenity.tools.romanToArabic() {
  local -A value
  value=( [M]=1000
          [D]=500
          [C]=100
          [L]=50
          [X]=10
          [V]=5
          [I]=1
  )
  local currentDigit
  local result=0
  local previousValue=0
  local currentValue=0
  for currentDigit in $(serenity.tools.characters "${1^^}"); do
    currentValue=${value[$currentDigit]}
    if [ $previousValue -lt $currentValue ]; then
      result=$((result-previousValue))
    else
      result=$((result+previousValue))
    fi
    previousValue=$currentValue
  done
  result=$((result+previousValue))
  echo $result
}

serenity.tools.contains() {
  local item
  local match="$1"
  shift

  for item; do
    [ "$item" = "$match" ] &&
    return 0
  done
  return 1
}
