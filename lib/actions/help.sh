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

# Show help text

serenity.actions.help.run() {
  cat << EOF
Usage: ${serenity_env_executable} [OPTION]... FILE

Options and arguments:

  -d              dry-run; don't rename files, only print their new name
  -t              only test if FILE's name follows a recognizable pattern
  -o <string>     set output prefix [default: none]
  -f              do not prompt before overwriting
  -i              prompt before overwrite
  -b              backup each existing destination file
  -n              do not overwrite an existing file
  -h              show help and exit

EOF
    return 1
}
