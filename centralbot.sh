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

. json.sh

BOTKEY_FILE="$(dirname "$0")/.botkey" # This file should have the ID of your bot
BOTKEY="$(cat "$BOTKEY_FILE")"        # Optionally, set it here as a variable
LAST_OFFSET=0

while true; do
    MESSAGE="$(curl --silent "https://api.telegram.org/bot$BOTKEY/getUpdates" --data 'limit=1' --data 'offset='"$LAST_OFFSET")"
    MESSAGE_SH_LINES=0

    json_decode "$MESSAGE" ".message.sh"
    sed 's/^\([^=]*\)=.*$/unset \1/' < ".message.sh" > ".message_unset.sh" &
    . .message.sh

    LAST_OFFSET="$(expr $json_result_1_update_id + 1)"
    MESSAGE_SH_LINES="$(wc -l < ".message.sh")"

    if [ $MESSAGE_SH_LINES -gt 1 ]; then
        bash rousbot.sh
    fi

    while [ ! -f ".message_unset.sh" ]; do :; done
    . .message_unset.sh
    rm --force ".message.sh"
    rm --force ".message_unset.sh"

    if [ $MESSAGE_SH_LINES -le 1 ]; then
        sleep 1s
    fi
done
