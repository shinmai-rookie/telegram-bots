#!/bin/bash

# centralbot.sh: Central bot; downloads and processes messages, and calls the
#     bots
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

# Path of this script
BIN_DIR="$(dirname "$0")"
. "$BIN_DIR/json.sh"

BOTS=("$BIN_DIR/rousbot.sh")        # Bots to run (should be runnable programs)
BOTKEY_FILE="$BIN_DIR/.botkey"      # This file should have the ID of your bot
BOTKEY="$(cat "$BOTKEY_FILE")"      # Optionally, set it here as a variable

# Number following the update_id of the last message
# It's a kind of lower limit for the update_id of the following message
# It also removes the previous messages
NEXT_OFFSET=0

# Path of the shell script that defines the JSON variables
MESSAGE_SH="$BIN_DIR/.message.sh"
# Path of the shell script that unsets the JSON variables
MESSAGE_UNSET_SH="$BIN_DIR/.message_unset.sh"

while true; do
    MESSAGE="$(curl --silent "https://api.telegram.org/bot$BOTKEY/getUpdates" --data 'limit=1' --data 'offset='"$NEXT_OFFSET")"
    # Number of lines of the file $MESSAGE_SH
    MESSAGE_SH_LINES=0

    # Create both shell scripts and load the one with the assignments
    json_decode "$MESSAGE" "$MESSAGE_SH"
    sed 's/^\([^=]*\)=.*$/unset \1/' < "$MESSAGE_SH" > "$MESSAGE_UNSET_SH" &
    . "$MESSAGE_SH"

    # Define two variables: the lower limit for the offset, and the number of
    # lines of the scripts
    NEXT_OFFSET="$(expr $json_result_1_update_id + 1)"
    MESSAGE_SH_LINES="$(wc -l < "$MESSAGE_SH")"

    # If the message is not empty, run the bots
    if [ $MESSAGE_SH_LINES -gt 1 ]; then
        for i in $(seq 0 `expr ${#BOTS[@]} - 1`); do
            ./"${BOTS[$i]}"
        done
    fi

    # Wait until the unset script has been written and load it
    while [ ! -f "$MESSAGE_UNSET_SH" ]; do :; done
    . "$MESSAGE_UNSET_SH"

    # Delete both scripts
    rm --force "$MESSAGE_SH"
    rm --force "$MESSAGE_UNSET_SH"

    # If the last message was empty (didn't have any content besides `ok=true')
    if [ $MESSAGE_SH_LINES -le 1 ]; then
        sleep 1s
    fi
done
