#!/bin/bash

# Rousbot: Send send a message as soon as a message matches one of the given
#     patterns
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

BOTKEY_FILE="$(dirname "$0")/.botkey" # This file should have the ID of your bot
BOTKEY="$(cat "$BOTKEY_FILE")"       # Optionally, set it here as a variable

# In this file you write the names of the users, with their IDs
# The lines of this file have a name, a comma (`,'), and a number each
# They make the code more readable than hard-coding the IDs
USER_ID_FILE="$(dirname "$0")/.userid"


# >> get_user_id $USER_NAME
#   Return the ID of $USER_NAME, which is a name written in the file $USER_ID_FILE
#  $USER_NAME can be a grep pattern (it CANNOT use `^' and `$' with their usual
#  meanings, though), but note that it will only match ONE line

function get_user_id
{
    USER_NAME="$1"
    ID="$(grep "^$1,[-0-9]*$" < "$USER_ID_FILE" | head --lines=1 | cut --delimiter=',' --fields=2 --only-delimited)"
    echo "$ID"
}


# >> send_message $MESSAGE_TEXT $CHAT_ROOM
#   Send the message $MESSAGE_TEXT to $CHAT_ROOM

function send_message
{
    MESSAGE_TEXT="$1"
    CHAT_ROOM="$2"

    echo "Sending \`$MESSAGE_TEXT' to \`$CHAT_ROOM'"
#    curl "https://api.telegram.org/bot$BOTKEY/sendMessage" --data 'chat_id='"$CHAT_ROOM" --data 'text='"$MESSAGE_TEXT" &> /dev/null
}


# >> send_message $ACTION
#   Runs a numbered action, defined here beforehand

function action
{
    ACTION=$1

    case $ACTION in
        1)  send_message 'Someone triggered the action 1!' $(get_user_id Me)
            ;;
    esac
}


# Events that trigger this bot
# A single message can trigger more than one event
# The first two fields (sender and message) can be negated with a leading `!'
# The last field is a command if it has a leading `#', or a message that will
# be sent to the chat the messages come from if it doesn't have a leading `#'
EVENTS=(
   # When this person      | says this                                      | send this
    '.*'                    '\(Rous\|ROUS\|Rosa\|ROSA\|\\ud83c\\udf39\)'     'Rous mola'
    !$(get_user_id "Me")    '\(Rous\|ROUS\|Rosa\|ROSA\|\\ud83c\\udf39\)'     '#action 1'
)

. .message.sh
# Extract the chat ID where the current message comes from
CHAT="$json_result_1_message_chat_id"
# Author of the message
FROM="$json_result_1_message_from_id"

for i in $(seq 0 3 $(expr ${#EVENTS[@]} - 1)); do
    # For every event in $EVENTS, this is the condition on the sender and
    # on the text that triggers, and the action that is carried or message
    # that is sent
    SENDER="${EVENTS[$i]}"
    TEXT="${EVENTS[$(expr $i + 1)]}"
    EVENT="${EVENTS[$(expr $i + 2)]}"

    # The `*_P' variables are equal to 1 if the part of the trigger they
    # refer to is negated, and 0 if it's not, except for EVENT_P (1 if it's
    # a message, and 0 if it's a command)
    SENDER_P=0
    TEXT_P=0
    EVENT_P=0

    [ ${SENDER:0:1} = '!' ] && SENDER="${SENDER:1}" SENDER_P=1
    [ ${TEXT:0:1} = '!' ] && TEXT="${TEXT:1}" TEXT_P=1
    [ ${EVENT:0:1} = '#' ] && EVENT="${EVENT:1}" EVENT_P=1

    # Test if the message does and must match, or doesn't and mustn't match
    # If neither condition is true, we continue
    grep --quiet "${TEXT}" <<< "$json_result_1_message_text"
    ! [ $? -eq $TEXT_P ] && continue

    # Test if the sender does and must match, or doesn't and mustn't match
    # If neither condition is true, we continue
    grep --quiet "$SENDER" <<< "$FROM"
    ! [ $? -eq $SENDER_P ] && continue

    # If it's a function, we run it
    [ $EVENT_P -eq 1 ] && $EVENT
    # If it's a message, we send it
    [ $EVENT_P -ne 1 ] && send_message "$EVENT" "$CHAT"
done
