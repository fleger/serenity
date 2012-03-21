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

# Dynamic pipelining

# Add a filter to the pipeline definition
serenity.pipeline.add() {
  if [ $# -gt 0 ]; then
    _pipeline+=($#)
    _pipeline+=("$@")
  fi
}

# Consume one filter from the pipeline and move to the next
serenity.pipeline._consume() {
  if [ ${#_pipeline[@]} -gt 0 ]; then
    local nItems=${_pipeline[0]}
    local -a pipelineCommand=("${_pipeline[@]:1:$nItems}")
    _pipeline=("${_pipeline[@]:$(( $nItems + 1 ))}")
    "${pipelineCommand[@]}" | serenity.pipeline._consume
  else
    echo "$(< /dev/stdin)"
  fi
}

# Execute a pipeline definition
serenity.pipeline.execute() {
  local -a _pipeline=()

  "${@}"

  serenity.pipeline._consume
}
