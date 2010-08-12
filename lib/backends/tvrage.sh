readonly serenity_backends_tvrage_REQUEST_PATTERN="http://services.tvrage.com/tools/quickinfo.php?show=%SHOW_NAME%&ep=%SEASON_NB%x%EPISODE_NB%"

serenity.backends.tvrage.extractShowName() {
    local r=$(echo "$1" | grep "^Show Name@") &&
    echo "$r" | sed -e "s/^Show Name@//"
}

serenity.backends.tvrage.extractEpisodeName() {
    local r=$(echo "$1" | grep "^Episode Info@") &&
    echo "$r" | cut --delimiter="^" --fields=2
}

serenity.backends.tvrage() {
    local showName="""$(serenity.tools.urlEncode "$1")""" &&
    local seasonNb="""$(serenity.tools.urlEncode "$2")""" &&
    local episodeNb="""$(serenity.tools.urlEncode "$3")""" &&
    local request="""$(echo "${serenity_backends_tvrage_REQUEST_PATTERN}" | sed -e "s/%SHOW_NAME%/$showName/" -e "s/%SEASON_NB%/$seasonNb/" -e "s/%EPISODE_NB%/$episodeNb/")""" &&
#     echo -e "Request: \n$request" &&
    local response="""$(curl -s "$request")""" &&
#     echo -e "Response: \n$response" &&
    echo """$(serenity.backends.tvrage.extractShowName "$response")""" &&
    echo "$2" &&
    echo "$3" &&
    echo """$(serenity.backends.tvrage.extractEpisodeName "$response")"""
}
