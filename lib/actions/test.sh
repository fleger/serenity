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


# serenity.actions.test.run [OPTIONS]... FILES...
# Test action entry point
serenity.actions.test.help() {
cat << EOM
test FILENAME

  Test if FILENAME matches a recognizable pattern.
EOM
}

serenity.actions.test.run() {
  serenity.actions.test.processFile "${1}" || {
    serenity.debug.info "Not a recognizable filename."
    return 1
  }
  serenity.debug.info "Done."
}

# serenity.actions.test.processFile FILE
# Process FILE
serenity.actions.test.processFile() {
  serenity.debug.info "Processing ${1}..."
  local fileName="$(basename "${1}")"
  serenity.pipeline.execute serenity.actions.test.definitions.global <<< "${fileName}"
}

# Processing definitions

# Global test process definition
# Closures: serenity.main, serenity.pipeline.execute
serenity.actions.test.definitions.global() {
  serenity.pipeline.add serenity.debug.trace serenity.processing.callFilterChain "$serenity_conf_globalPreprocessing"
  # FIXME: pass configuration
  serenity.pipeline.add serenity.debug.trace serenity.tokens.execute serenity.actions.test.definitions.tokens
}

serenity.actions.test.definitions.tokens() {
  serenity.tokens.add serenity.processing.tokenization
}