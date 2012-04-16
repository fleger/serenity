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

# Serenity naked configuration file

local -a serenity_conf__tokenizers=()
local -a serenity_conf__tokenizerLengths=()

serenity.conf.addTokenizer() {
  if [ "$#" -gt 0 ]; then
    serenity_conf__tokenizerLengths+=("${#}")
    serenity_conf__tokenizers+=("${@}")
  else
    serenity.debug.error "serenity.conf.addTokenizer: missing armguments"
    return 1
  fi
}

local serenity_conf_globalPreprocessing=''
local -A serenity_conf_tokenDefaults=()
local -A serenity_conf_tokenPreprocessing=()
local -a serenity_conf_splitterPriorities=()
local -a serenity_conf_refiningBackends=('dummy')
local -a serenity_conf_aggregatorPriorities=()
local -A serenity_conf_tokenPostprocessing=()
local -a serenity_conf_formatting=()
local serenity_conf_globalPostprocessing=''
local serenity_conf_tracing='no'
local serenity_conf_keepExtension='yes'
local -a serenity_conf_multipartStripList=()

local serenity_conf_dryRun=false
local serenity_conf_test=false
local serenity_conf_outputPrefix="."
local -a serenity_conf_mvArgs=()
