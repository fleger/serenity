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



serenity.actions.test.help() {
cat << EOM
test FILENAME

  Test if FILENAME matches a recognizable pattern.
EOM
}

# serenity.actions.test.run [OPTIONS]... FILES...
# Test action entry point
serenity.actions.test.run() {
  serenity.tokens: serenity.actions.test.definitions.global "${1}" || {
    serenity.debug.info "Not a recognizable filename."
    return 1
  }
  serenity.debug.info "Done."
}

# serenity.actions.test.definitions.global FILE
#
# Global test process definition for FILE
#
# Closures: serenity:, serenity.tokens:
serenity.actions.test.definitions.global() {
  serenity.tokens- serenity.tokens.set "_::input_filename" "$(basename "${1}")"
  serenity.tokens- serenity.processing.callFilterChainOnToken "$serenity_conf_globalPreprocessing" "_::input_filename"
  serenity.tokens- serenity.processing.tokenization "_::input_filename"
}
