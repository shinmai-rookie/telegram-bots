#!/bin/bash
# json: Parse JSON files through (partly) a sed script
# Copyright (C) 2016  Jaime Mosquera
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# >> json_decode $MESSAGE $OUTPUT_FILE
#   Decode the JSON message $MESSAGE and write a valid shell file with
#  variable assignments for the JSON file

function json_decode
{
    PREFIXES=( "" )
    PREFIX_N=-1
    PREFIX=""

    ARRAY_NAME=( )

    ARRAY_COUNT=( )
    COUNT_N=-1

    MESSAGE="$1"
    OUTPUT_FILE="$2"

    sed -f json.sed <<< "$MESSAGE" |
    while read LINE; do
        # If a line ends in a `=', it means an array follows, so we add
        # another array name
        if [ -z "${LINE##*=}" ]; then
            ARRAY_NAME[$(expr $COUNT_N + 1)]="${LINE%%=}"

        # If a line is a valid assignment, we add the prefix to the variable
        # name
        elif [[ "$LINE" == *"="* ]]; then
            VAR="${LINE%%=*}"
            VAR="$(sed 's/-/_/g' <<< "${VAR}")"
            DEF="${LINE#*=}"
            NEW_LINE="$PREFIX$VAR=$DEF"

            echo "$NEW_LINE"

        # If a line is `START "object"', add `object' to the prefix of the
        # variables
        elif [[ "$LINE" == "START \""*"\"" ]]; then
            NEW_PREFIX=${LINE##"START \""}
            NEW_PREFIX=${NEW_PREFIX%%"\""}
            PREFIX_N=$(expr $PREFIX_N + 1)
            PREFIXES[$PREFIX_N]="$NEW_PREFIX"
            PREFIX="$PREFIX${NEW_PREFIX}_"

        # If a line is START_ARRAY, a new array begins
        # The name of the array is added as a prefix, and a new array counter
        # is added
        elif [ "$LINE" = "START_ARRAY" ]; then
            COUNT_N=$(expr $COUNT_N + 1)
            ARRAY_COUNT[$COUNT_N]=0
            PREFIX_N=$(expr $PREFIX_N + 1)
            PREFIXES[$PREFIX_N]="$ARRAY_NAME"
            PREFIX="$PREFIX${ARRAY_NAME}_"

        # If a line is END_ARRAY, the array ends
        # Take the name of the array from the prefixes and the list of array
        # names
        elif [ "$LINE" = "END_ARRAY" ]; then
            CURRENT_PREFIX="${PREFIXES[$PREFIX_N]}"
            CURRENT_PREFIX="${CURRENT_PREFIX:1}"
            ARRAY_COUNT[$COUNT_N]=0
            ARRAY_NAME[$COUNT_N]=""
            PREFIX="${PREFIX%%${CURRENT_PREFIX}_}"
            COUNT_N=$(expr $COUNT_N - 1)
            PREFIXES[$PREFIX_N]=""
            PREFIX_N=$(expr $PREFIX_N - 1)

        # START is found wherever `{' was in the original file without a
        # previous identifier, which means it's a new object in an array of
        # objects
        # Consequently, the counter of the array is increased
        elif [ "$LINE" = "START" ]; then
            PREFIX="${PREFIX%%${ARRAY_COUNT[$COUNT_N]}_}"
            ARRAY_COUNT[$COUNT_N]=$(expr ${ARRAY_COUNT[$COUNT_N]} + 1)
            PREFIX="$PREFIX${ARRAY_COUNT[$COUNT_N]}_"

        # LESS is found wherever `}' was in the original file
        # It means an object is finished, so we take the prefix from it
        elif [ "$LINE" = "LESS" ]; then
            PREFIX="${PREFIX%%${PREFIXES[$PREFIX_N]}_}"
            PREFIXES[$PREFIX_N]=""
            PREFIX_N="$(expr $PREFIX_N - 1)"
        fi
    done >> "$OUTPUT_FILE"
}
