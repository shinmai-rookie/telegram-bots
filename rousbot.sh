#!/bin/sh

# Telebot: Send send a message as soon as a message matches one of the given
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
# 
# Also add information on how to contact you by electronic and paper mail.

LAST_OFFSET=0                # ID of the last analysed message
BOTKEY="$(cat .botkey)"      # Here you write the ID of the bot; without it, nothing works!
TEXT_TO_FIND=( '\(Rous\|ROUS\|Rosa\|ROSA\)' '\(peta\|PETA\)' )
TEXT_TO_SEND=( 'Rous mola'                  'Dora lo peta' )

while true
do
    # Read the next message in any group or chat this bot is in
    MESSAGE="$(curl --silent "https://api.telegram.org/bot$BOTKEY/getUpdates" --data 'limit=1' --data 'offset='"$LAST_OFFSET")"
    # Extract the update ID of the current message
    OFFSET="$(sed 's/^.*"update_id":\([-0-9]\{1,10\}\),.*$/\1/;2d' <<< "$MESSAGE")"
    # Extract the chat ID where the current message comes from
    CHAT="$(sed 's/^.*"chat":{"id":\([-0-9]\{1,10\}\),.*$/\1/;1d' <<< "$MESSAGE")"

    for i in $(seq 0 $(expr ${#TEXT_TO_FIND[@]} - 1))
    do
        # If any of the given patterns are found, the appropriate message is
        # sent
        if grep --quiet '"text":".*'"${TEXT_TO_FIND[$i]}" <<< "$MESSAGE"
        then
            curl "https://api.telegram.org/bot$BOTKEY/sendMessage" --data 'chat_id='"$CHAT" --data 'text='"${TEXT_TO_SEND[$i]}" &> /dev/null
        fi
    done

    # Finding a chat ID means that there has been an update
    if test "x$CHAT" != "x"
    then
        LAST_OFFSET="`expr $OFFSET + 1`"
    fi

    sleep 1s
done
