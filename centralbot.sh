#MESSAGE="$(curl --silent "https://api.telegram.org/bot$BOTKEY/getUpdates" --data 'limit=1' --data 'offset='"$LAST_OFFSET" | sed -f json.sed )"
MESSAGE="$(cat output)"


FINAL_FILE=""

PREFIXES=( "" )
PREFIX_N=-1
PREFIX=""

ARRAY_NAME=( )

ARRAY_COUNT=( )
COUNT_N=-1

set -x

sed -f json.sed <<< "$MESSAGE" |
sed 's/^[ 	]*//g; s/[ 	]*$//g; /^$/ d' |
while read LINE; do
    if [ -z "${LINE##*=}" ]; then
        ARRAY_NAME+=( ${LINE%%=} )
    elif [[ "$LINE" == *"="* ]]; then
        VAR="${LINE%%=*}"
        DEF="${LINE#*=}"
        NEW_LINE="$PREFIX$VAR=$DEF"
        FINAL_FILE="$FINAL_FILE$NEW_LINE"$'\n'
    elif [[ "$LINE" == "START \""*"\"" ]]; then
        NEW_PREFIX=${LINE##"START \""}
        NEW_PREFIX=${NEW_PREFIX%%"\""}
        PREFIXES+=($NEW_PREFIX)
        PREFIX="$PREFIX${NEW_PREFIX}_"
        PREFIX_N=$(expr $PREFIX_N + 1)
    elif [ "$LINE" = "START_ARRAY" ]; then
        ARRAY_COUNT+=(0)
        COUNT_N=$(expr $COUNT_N + 1)
        PREFIX="$PREFIX${ARRAY_NAME}_"
        PREFIXES+=(".$ARRAY_NAME")
        PREFIX_N=$(expr $PREFIX_N + 1)
    elif [ "$LINE" = "START" ]; then
        PREFIX="${PREFIX%%${ARRAY_COUNT[$COUNT_N]}_}"
        ARRAY_COUNT[$COUNT_N]=$(expr ${ARRAY_COUNT[$COUNT_N]} + 1)
        PREFIX="$PREFIX${ARRAY_COUNT[$COUNT_N]}_"
    elif [[ "$LINE" == "LESS" ]]; then
        CURRENT_PREFIX="${PREFIXES[$PREFIX_N]}"
        if [ "${CURRENT_PREFIX:0:1}" = '.' ]; then
            CURRENT_PREFIX="${CURRENT_PREFIX:1}"
            ARRAY_COUNT[$COUNT_N]=0
            ARRAY_NAME[$COUNT_N]=""
            COUNT_N=$(expr $COUNT_N - 1)
        fi

        PREFIX="${PREFIX%%${CURRENT_PREFIX}_}"
        PREFIXES[$PREFIX_N]=""
        PREFIX_N="$(expr $PREFIX_N - 1)"
    fi

    echo "$FINAL_FILE"
done

#echo "$FINAL_FILE"
