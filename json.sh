#!/bin/bash

# json.sh: Parse JSON files through (partly) a sed script and generate a shell
#     script with assignments to access the JSON properties
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

# >> json_decode ${MESSAGE} ${OUTPUT_FILE}
#   Decode the JSON message ${MESSAGE} and write a valid shell file with
#  variable assignments for the JSON file

function json_decode
{
    # Prefixes attached to variable names

    # List of prefixes
    PREFIXES=( )
    # Number of prefixes in the list
    PREFIX_N=-1
    # Composite prefix, formed by all the prefixes
    PREFIX=""


    # Prefixes attached to the variables of the arrays

    # List of variable names inside the arrays
    # It is an array because JSON arrays can be nested
    ARRAY_NAME=( )
    # Counter of elements in the array
    # It is an array because JSON arrays can be nested
    ARRAY_COUNT=( )
    # Number of array names and counters in the two previous variables
    COUNT_N=-1


    # Message that will be decoded
    MESSAGE="$1"
    # File where the result will be saved
    OUTPUT_FILE="$2"


    # The second `sed' is needed because somehow backslashes get lost while
    # reading them, but the next character after them (even it it is another
    # backslash) is preserved
    sed -f json.sed <<< "${MESSAGE}" |
    sed 's/\\/\\\\/g; s/^[ 	]*//g; s/[ 	]*$//g' |
    while read LINE; do
        # We ignore the empty lines at the beginning
        [ -z "${LINE}" ] && continue

        # If a line ends in a `=', it means an array follows, so we add
        # another array name
        if [ -z "${LINE##*=}" ]; then
            ARRAY_NAME[$(expr ${COUNT_N} + 1)]="${LINE%%=}"

        # If a line is a valid assignment, we add the prefix to the variable
        # name
        elif [[ "${LINE}" == *"="* ]]; then
            VAR="${LINE%%=*}"
            VAR="$(sed 's/-/_/g' <<< "${VAR}")"
            DEF="${LINE#*=}"
            NEW_LINE="${PREFIX}${VAR}=${DEF}"

            echo "${NEW_LINE}"

        # If a line is `START "object"', add `object' to the prefix of the
        # variables
        elif [[ "${LINE}" == "START '"*"'" ]]; then
            NEW_PREFIX=${LINE##"START '"}
            NEW_PREFIX=${NEW_PREFIX%%"'"}
            PREFIX_N=$(expr ${PREFIX_N} + 1)
            PREFIXES[${PREFIX_N}]="${NEW_PREFIX}"
            PREFIX="${PREFIX}${NEW_PREFIX}_"

        # If a line is START_ARRAY, a new array begins
        # The name of the array is added as a prefix, and a new array counter
        # is added
        elif [ "${LINE}" = "START_ARRAY" ]; then
            COUNT_N=$(expr ${COUNT_N} + 1)
            ARRAY_COUNT[${COUNT_N}]=0
            PREFIX_N=$(expr ${PREFIX_N} + 1)
            PREFIXES[${PREFIX_N}]="${ARRAY_NAME}"
            PREFIX="${PREFIX}${ARRAY_NAME}_"

        # If a line is END_ARRAY, the array ends
        # Take the name of the array from the prefixes and the list of array
        # names
        elif [ "${LINE}" = "END_ARRAY" ]; then
            echo "${PREFIX}0=${ARRAY_COUNT[${COUNT_N}]}"

            CURRENT_PREFIX="${PREFIXES[${PREFIX_N}]}"
            CURRENT_PREFIX="${CURRENT_PREFIX:1}"
            ARRAY_COUNT[${COUNT_N}]=0
            ARRAY_NAME[${COUNT_N}]=""
            PREFIX="${PREFIX%%${CURRENT_PREFIX}_}"
            COUNT_N=$(expr ${COUNT_N} - 1)
            PREFIXES[${PREFIX_N}]=""
            PREFIX_N=$(expr ${PREFIX_N} - 1)

        # START is found wherever `{' was in the original file without a
        # previous identifier, which means it is a new object in an array of
        # objects
        # Consequently, the counter of the array is increased
        elif [ "${LINE}" = "START" ]; then
            PREFIX="${PREFIX%%${ARRAY_COUNT[${COUNT_N}]}_}"
            ARRAY_COUNT[${COUNT_N}]=$(expr ${ARRAY_COUNT[${COUNT_N}]} + 1)
            PREFIX="${PREFIX}${ARRAY_COUNT[${COUNT_N}]}_"

        # LESS is found wherever `}' was in the original file
        # It means an object is finished, so we take the prefix from it
        elif [ "${LINE}" = "LESS" ]; then
            PREFIX="${PREFIX%%${PREFIXES[${PREFIX_N}]}_}"
            PREFIXES[${PREFIX_N}]=""
            PREFIX_N="$(expr ${PREFIX_N} - 1)"

        # If nothing else matches, assume it is a element of an array of
        # primitive elements
        else
            PREFIX="${PREFIX%%${ARRAY_COUNT[${COUNT_N}]}_}"
            ARRAY_COUNT[${COUNT_N}]=$(expr ${ARRAY_COUNT[${COUNT_N}]} + 1)
            PREFIX="${PREFIX}${ARRAY_COUNT[${COUNT_N}]}_"
            echo "${PREFIX%_}=${LINE}"
        fi
    done >> "${OUTPUT_FILE}"
}
