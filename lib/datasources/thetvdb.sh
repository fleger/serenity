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

# TheTVDB data source

serenity.datasources.thetvdb:() {
  serenity.debug.debug "TheTVDB: entering context"
  local -r SERENITY_DATASOURCES_THETVDB_API_KEY="BE137819321004FF"
  local -r SERENITY_DATASOURCES_THETVDB_CACHE_PATH="${serenity_env_cache}/datasources/thetvdb"
  local -r SERENITY_DATASOURCES_THETVDB_SEARCH_LANGUAGE="all"

  local -ir SERENITY_DATASOURCES_THETVDB_UPDATE_DAY=$((60 * 60 * 24))
  local -ir SERENITY_DATASOURCES_THETVDB_UPDATE_WEEK=$((60 * 60 * 24 * 7))
  local -ir SERENITY_DATASOURCES_THETVDB_UPDATE_MONTH=$((60 * 60 * 24 * 30))
  local -ir SERENITY_DATASOURCES_THETVDB_UPDATE_ALL=-1
  local -ir SERENITY_DATASOURCES_THETVDB_UPDATE_NONE=0

  local -Ar SERENITY_DATASOURCES_THETVDB_UPDATE_SUFFIX_MAPPINGS=(
    ["$SERENITY_DATASOURCES_THETVDB_UPDATE_DAY"]="day"
    ["$SERENITY_DATASOURCES_THETVDB_UPDATE_WEEK"]="week"
    ["$SERENITY_DATASOURCES_THETVDB_UPDATE_MONTH"]="month"
    ["$SERENITY_DATASOURCES_THETVDB_UPDATE_ALL"]="all"
  )

  local -a serenity_datasources_thetvdb_upToDateSeriesIdls=()
  local -A serenity_datasources_thetvdb_cachedSeriesIdls=()
  local serenity_datasources_thetvdb_initialized=false
  local -i serenity_datasources_thetvdb_fetchedUpdate="$SERENITY_DATASOURCES_THETVDB_UPDATE_NONE"
  local -a serenity_datasources_thetvdb_zipMirrors=()
  local -a serenity_datasources_thetvdb_bannerMirrors=()
  local -a serenity_datasources_thetvdb_xmlMirrors=()
 
  local -i serenity_datasources_thetvdb_serverTime=0
  
  "$@"

  serenity.datasources.thetvdb.removeUpdatesFromCache
}

serenity.datasources.thetvdb.init() {
  mkdir -p "$SERENITY_DATASOURCES_THETVDB_CACHE_PATH"
  serenity.datasources.thetvdb.initMirrors || return 1
  serenity.datasources.thetvdb.initServerTime  || return 2
  serenity_datasources_thetvdb_initialized=true
}

serenity.datasources.thetvdb.initMirrors() {
  local -ri XML_FILES=1
  local -ri BANNER_FILES=2
  local -ri ZIP_FILES=4

  local mirrorPath
  local -i typeMask

  local mirrorFile="$SERENITY_DATASOURCES_THETVDB_CACHE_PATH/mirrors.xml"
  serenity.datasources.thetvdb.fetchMirrors "$mirrorFile" || return 1

  while read mirrorPath typeMask; do
    if [[ $typeMask -ge $ZIP_FILES ]]; then
      serenity_datasources_thetvdb_zipMirrors+=("$mirrorPath")
      typeMask=$(($typeMask - $ZIP_FILES))
    fi
    if [[ $typeMask -ge $BANNER_FILES ]]; then
      serenity_datasources_thetvdb_bannerMirrors+=("$mirrorPath")
      typeMask=$(($typeMask - $BANNER_FILES))
    fi
    if [[ $typeMask -ge $XML_FILES ]]; then
      serenity_datasources_thetvdb_xmlMirrors+=("$mirrorPath")
      typeMask=$(($typeMask - $XML_FILES))
    fi
  done < <(serenity.tools.lockFile -s "$mirrorFile" \
           xmlstarlet sel -T -t -m "/Mirrors/Mirror" -v "mirrorpath" -o " " -v 'typemask' -n < \
           "$mirrorFile")
}

serenity.datasources.thetvdb.fetchMirrors() {
  serenity.tools.lockFile "$1" serenity.datasources.thetvdb.__fetchMirrors "$1"
}

serenity.datasources.thetvdb.__fetchMirrors() {
  if [[ ! -s "$1" ]]; then
    serenity.debug.debug "TheTVDB: fetching mirrors from www.thetvdb.com"
    curl -s "http://www.thetvdb.com/api/${SERENITY_DATASOURCES_THETVDB_API_KEY}/mirrors.xml" > \
      "$1" || return 1
  fi
}

serenity.datasources.thetvdb.initServerTime() {
  serenity_datasources_thetvdb_serverTime=$(curl -s "http://www.thetvdb.com/api/Updates.php?type=none" |
    xmlstarlet sel -T -t -v "/Items/Time" -n) || return 1
  serenity.debug.debug "TheTVDB: server time set to $serenity_datasources_thetvdb_serverTime"
}

serenity.datasources.thetvdb.removeUpdatesFromCache() {
  [[ -f "$SERENITY_DATASOURCES_THETVDB_CACHE_PATH/updates.zip" ]] &&
  rm "$SERENITY_DATASOURCES_THETVDB_CACHE_PATH/updates.zip"
}

serenity.datasources.thetvdb.run() {
  if ! $serenity_datasources_thetvdb_initialized; then
    serenity.datasources.thetvdb.init || {
      serenity.debug.error "TheTVDB: initialization failed"
      return 1
    }
  fi

  local seriesIdl
  local show="$(serenity.tokens.get "show")"

  serenity.datasources.thetvdb.getSeriesIdl "$show" || {
    serenity.debug.warning "TheTVDB: failed to get series Id & language"
    return 2
  }

  serenity.debug.debug "TheTVDB: idl=${serenity_datasources_thetvdb_cachedSeriesIdls["$show"]}"

  serenity.datasources.thetvdb.getEpisode "${serenity_datasources_thetvdb_cachedSeriesIdls["$show"]%-*}" \
                                               "${serenity_datasources_thetvdb_cachedSeriesIdls["$show"]##*-}"

  serenity.tokens.isSet "title" || {
    serenity.debug.warning "TheTVDB: title not set. This may be due to a bad season/episode number."
    return 3
  }
}

serenity.datasources.thetvdb.getEpisode() {
  local seriesId="$1"
  local language="$2"

  serenity.datasources.thetvdb.fetchSeries "$seriesId" "$language" || {
    serenity.debug.error "TheTVDB: could not fetch series $seriesId-$language"
    return 1
  }

  local key
  local value

  while read key value; do
    serenity.tokens.set "$key" "$value"
  done < <(
    serenity.datasources.thetvdb.readZippedFile "$SERENITY_DATASOURCES_THETVDB_CACHE_PATH/$seriesId-$language.zip" "$language.xml" |
      xmlstarlet sel -T \
        -t -m '/Data/Series' \
          -o 'show '          -v 'SeriesName'     -n    \
          -o 'started '       -v 'FirstAired'     -n    \
          -o 'language '      -v 'Language'       -n    \
          -o 'status '        -v 'Status'         -n    \
          -o 'genres '        -v 'Genre'          -n    \
          -o 'contentRating ' -v 'ContentRating'  -n    \
          -o 'network '       -v 'Network'        -n    \
          -o 'runtime '       -v 'Runtime'        -n    \
        -t -m '/Data/Episode' -i "SeasonNumber = $(serenity.tokens.get "season") and EpisodeNumber = $(serenity.tokens.get "episode")" \
          -o 'title '         -v 'EpisodeName'    -n    \
          -o 'date '          -v 'FirstAired'     -n
  )
}

serenity.datasources.thetvdb.fetchSeries() {
  local seriesId="$1"
  local language="$2"

  if serenity.tools.contains "$seriesId-$language" "${serenity_datasources_thetvdb_upToDateSeriesIdls[@]}"; then
    # Already up-to-date
    return 0
  elif [[ -s "$SERENITY_DATASOURCES_THETVDB_CACHE_PATH/$seriesId-$language.zip" ]]; then
    local -i lastUpdated
    lastUpdated="$(serenity.datasources.thetvdb.readZippedFile "$SERENITY_DATASOURCES_THETVDB_CACHE_PATH/$seriesId-$language.zip" "$language.xml" |
                    xmlstarlet sel -T -t -m '/Data/Series' -v 'lastupdated')"
    serenity.datasources.thetvdb.fetchUpdates "$lastUpdated"
    serenity.datasources.thetvdb.isSeriesDirty "$seriesId" "$lastUpdated" || {
      serenity_datasources_thetvdb_upToDateSeriesIdls+=("$seriesId-$language")
      return 0
    }
  fi

  serenity.debug.debug "TheTVDB: Update required for $seriesId-$language"
  # TODO: try to use the cache even if the request fails
  curl -s "$(serenity.datasources.thetvdb.pickZipMirror)/api/${SERENITY_DATASOURCES_THETVDB_API_KEY}/series/$seriesId/all/$language.zip" > \
    "$SERENITY_DATASOURCES_THETVDB_CACHE_PATH/$seriesId-$language.zip" || return 1
  serenity_datasources_thetvdb_upToDateSeriesIdls+=("$seriesId-$language")
}

serenity.datasources.thetvdb.isSeriesDirty() {
  if [[ "$serenity_datasources_thetvdb_fetchedUpdate" = "$SERENITY_DATASOURCES_THETVDB_UPDATE_NONE" ]]; then
    return 1
  fi

  local seriesId="$1"
  local -i lastUpdated="$2"
  local suffix
  suffix="${SERENITY_DATASOURCES_THETVDB_UPDATE_SUFFIX_MAPPINGS["$serenity_datasources_thetvdb_fetchedUpdate"]}"
  local -i lastUpdate
  lastUpdate="$(serenity.datasources.thetvdb.readZippedFile "$SERENITY_DATASOURCES_THETVDB_CACHE_PATH/updates.zip" "updates_$suffix.xml" |
    xmlstarlet sel -T -t -m "/Data/Series" -i "id = $seriesId" -v "time")"
  if [[ -n "$lastUpdate" ]] && (( $lastUpdated < $lastUpdate )); then
    return 0
  fi
  return 1
}

serenity.datasources.thetvdb.fetchUpdates() {
  if [[ "$serenity_datasources_thetvdb_fetchedUpdate" = "$SERENITY_DATASOURCES_THETVDB_UPDATE_ALL" ]]; then
    return 0
  fi

  local -i delta=$(($serenity_datasources_thetvdb_serverTime - $1))

  if (($delta <= $serenity_datasources_thetvdb_fetchedUpdate)); then
    return 0
  fi

  serenity.datasources.thetvdb.removeUpdatesFromCache
  serenity_datasources_thetvdb_fetchedUpdate="$SERENITY_DATASOURCES_THETVDB_UPDATE_NONE"

  if (($delta <= $SERENITY_DATASOURCES_THETVDB_UPDATE_DAY)); then
    serenity_datasources_thetvdb_fetchedUpdate="$SERENITY_DATASOURCES_THETVDB_UPDATE_DAY"
  elif (($delta <= $SERENITY_DATASOURCES_THETVDB_UPDATE_WEEK)); then
    serenity_datasources_thetvdb_fetchedUpdate="$SERENITY_DATASOURCES_THETVDB_UPDATE_WEEK"
  elif (($delta <= $SERENITY_DATASOURCES_THETVDB_UPDATE_MONTH)); then
    serenity_datasources_thetvdb_fetchedUpdate="$SERENITY_DATASOURCES_THETVDB_UPDATE_MONTH"
  else
    serenity_datasources_thetvdb_fetchedUpdate="$SERENITY_DATASOURCES_THETVDB_UPDATE_ALL"
  fi
  local suffix
  suffix="${SERENITY_DATASOURCES_THETVDB_UPDATE_SUFFIX_MAPPINGS["$serenity_datasources_thetvdb_fetchedUpdate"]}"
  serenity.debug.debug "TheTVDB: fetching updates_$suffix"
  curl -s "$(serenity.datasources.thetvdb.pickZipMirror)/api/${SERENITY_DATASOURCES_THETVDB_API_KEY}/updates/updates_$suffix.zip" > \
    "$SERENITY_DATASOURCES_THETVDB_CACHE_PATH/updates.zip" || {
      serenity_datasources_thetvdb_fetchedUpdate="$SERENITY_DATASOURCES_THETVDB_UPDATE_NONE"
      serenity.debug.warning "TheTVDB: failed to retreive updates_$suffix"
    }
}

serenity.datasources.thetvdb.readZippedFile() {
  bsdtar -Oxf "$1" "$2"
}

serenity.datasources.thetvdb.pickZipMirror() {
  # TODO: pick a random mirror
  echo "${serenity_datasources_thetvdb_zipMirrors[0]}"
}

serenity.datasources.thetvdb.getSeriesIdl() {
  if ! serenity.tools.contains "$1" "${!serenity_datasources_thetvdb_cachedSeriesIdls[@]}"; then
    serenity.debug.debug "TheTVDB: $1 idl not in cache"
    serenity_datasources_thetvdb_cachedSeriesIdls["$1"]="$(serenity.datasources.thetvdb.fetchSeriesIdl "$1")"
  fi
}

serenity.datasources.thetvdb.fetchSeriesIdl() {
  local language="$(serenity.filters.urlEncode <<< "$SERENITY_DATASOURCES_THETVDB_SEARCH_LANGUAGE")"
  local show="$(serenity.filters.urlEncode <<< "$1")"
  curl -s "http://www.thetvdb.com/api/GetSeries.php?seriesname=$show&language=$language" |
    xmlstarlet sel -T -t -m "/Data/Series[1]" -v "seriesid" -o "-" -v 'language'
}