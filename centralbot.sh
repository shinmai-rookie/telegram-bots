#MESSAGE="$(curl --silent "https://api.telegram.org/bot$BOTKEY/getUpdates" --data 'limit=1' --data 'offset='"$LAST_OFFSET" | sed -f json.sed )"
MESSAGE="$(cat output)"


FINAL_FILE=""

PREFIXES=( "" )
PREFIX_N=-1
PREFIX=""

ARRAY_NAME=( )

ARRAY_COUNT=( )
COUNT_N=-1

# This doesn't work on Bash < 4.2
# It makes the while loop not to be run in a different subshell
# Otherwise, FINAL_FILE wouldn't be preserved outside the loop
shopt -s lastpipe

sed -f json.sed <<< "$MESSAGE" |
while read LINE; do
    if [ -z "${LINE##*=}" ]; then
        ARRAY_NAME[$(expr $COUNT_N + 1)]="${LINE%%=}"

    elif [[ "$LINE" == *"="* ]]; then
        VAR="${LINE%%=*}"
        VAR="$(sed 's/-/_/g' <<< "${VAR}")"
        DEF="${LINE#*=}"
        NEW_LINE="$PREFIX$VAR=$DEF"
        FINAL_FILE="$FINAL_FILE$NEW_LINE"$'\n'

    elif [[ "$LINE" == "START \""*"\"" ]]; then
        NEW_PREFIX=${LINE##"START \""}
        NEW_PREFIX=${NEW_PREFIX%%"\""}
        PREFIX_N=$(expr $PREFIX_N + 1)
        PREFIXES[$PREFIX_N]="$NEW_PREFIX"
        PREFIX="$PREFIX${NEW_PREFIX}_"

    elif [ "$LINE" = "START_ARRAY" ]; then
        COUNT_N=$(expr $COUNT_N + 1)
        ARRAY_COUNT[$COUNT_N]=0
        PREFIX_N=$(expr $PREFIX_N + 1)
        PREFIXES[$PREFIX_N]="$ARRAY_NAME"
        PREFIX="$PREFIX${ARRAY_NAME}_"

    elif [ "$LINE" = "END_ARRAY" ]; then
        CURRENT_PREFIX="${PREFIXES[$PREFIX_N]}"
        CURRENT_PREFIX="${CURRENT_PREFIX:1}"
        ARRAY_COUNT[$COUNT_N]=0
        ARRAY_NAME[$COUNT_N]=""
        PREFIX="${PREFIX%%${CURRENT_PREFIX}_}"
        COUNT_N=$(expr $COUNT_N - 1)
        PREFIXES[$PREFIX_N]=""
        PREFIX_N=$(expr $PREFIX_N - 1)

    elif [ "$LINE" = "START" ]; then
        PREFIX="${PREFIX%%${ARRAY_COUNT[$COUNT_N]}_}"
        ARRAY_COUNT[$COUNT_N]=$(expr ${ARRAY_COUNT[$COUNT_N]} + 1)
        PREFIX="$PREFIX${ARRAY_COUNT[$COUNT_N]}_"

    elif [ "$LINE" = "LESS" ]; then
        PREFIX="${PREFIX%%${PREFIXES[$PREFIX_N]}_}"
        PREFIXES[$PREFIX_N]=""
        PREFIX_N="$(expr $PREFIX_N - 1)"
    fi
done

echo "$FINAL_FILE"
