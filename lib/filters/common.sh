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

readonly serenity_filters_romanNumeralRE="[IVXLCDMivxlcdm]"

serenity.filters.englishToArabic() {
  local inputBuffer="$(< /dev/stdin)"
  case "${inputBuffer,,*}" in
    "zero") echo 0;;
    "one") echo 1;;
    "two") echo 2;;
    "three") echo 3;;
    "four") echo 4;;
    "five") echo 5;;
    "six") echo 6;;
    "seven") echo 7;;
    "eight") echo 8;;
    "nine") echo 9;;
    "ten") echo 10;;
    "eleven") echo 11;;
    "twelve") echo 12;;
    "thirteen") echo 13;;
    "fourteen") echo 14;;
    "fifteen") echo 15;;
    "sixteen") echo 16;;
    "seventeen") echo 17;;
    "eighteen") echo 18;;
    "nineteen") echo 19;;
    *) echo "$inputBuffer";;
  esac
}

serenity.filters.romanToArabic() {
  local -Ar value=( [M]=1000
                    [D]=500
                    [C]=100
                    [L]=50
                    [X]=10
                    [V]=5
                    [I]=1)
  local currentDigit
  local result=0
  local previousValue=0
  local currentValue=0
  local inputBuffer="$(< /dev/stdin)"
  [[ "${number}" =~ ^${serenity_filters_romanNumeralRE}+$ ]] || {
    # Not a roman numeral
    echo "${inputBuffer}"
    return 0
  }
  for currentDigit in $(serenity.tools.characters "${inputBuffer^^}"); do
    currentValue=${value[$currentDigit]}
    if [ $previousValue -lt $currentValue ]; then
      result=$((result-previousValue))
    else
      result=$((result+previousValue))
    fi
    previousValue=$currentValue
  done
  result=$((result+previousValue))
  echo "${result}"
}

serenity.filters.lstrip() {
   local inputBuffer
   inputBuffer="$(< /dev/stdin)"
   echo "${inputBuffer##$1}"
}

serenity.filters.rstrip() {
   local inputBuffer
   inputBuffer="$(< /dev/stdin)"
   echo "${inputBuffer%%$1}"
}

serenity.filters.urlEncode() {
  local inputBuffer="$(< /dev/stdin)"
  while [[ "$inputBuffer" =~ ^([0-9a-zA-Z/:_\.\-]*)([^0-9a-zA-Z/:_\.\-])(.*) ]]; do
    echo -n "${BASH_REMATCH[1]}"
    printf "%%%X" "'${BASH_REMATCH[2]}'"
    inputBuffer="${BASH_REMATCH[3]}"
  done
  # the remaining part
  echo -n "$inputBuffer"
}

serenity.filters.urlDecode() {
  local inputBuffer="$(< /dev/stdin)"
  local i="0"
  while [ "$i" -lt ${#inputBuffer} ]; do
    local c0=${inputBuffer:$i:1}
    if [ "x$c0" = "x%" ]; then
      local c1=${inputBuffer:$((i+1)):1}
      local c2=${inputBuffer:$((i+2)):1}
      printf "\x$c1$c2"
      i=$((i+3))
    else
      echo -n "$c0"
      i=$((i+1))
    fi
  done
}
