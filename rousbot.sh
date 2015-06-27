#/bin/sh

# Rousbot: Send "Rous mola" whenever someone mentions Rosa (aka Rous)
# Copyright (C) 2015  Jaime Mosquera
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

LAST_OFFSET=0      # ID of the last analysed message
BOTKEY=""          # Here you write the ID of the bot; without it, nothing works!

while true
do
    # Read the next message in any group or chat Rousbot is in
    MESSAGE="`curl --silent "https://api.telegram.org/bot$BOTKEY/getUpdates" --data 'limit=1' --data 'offset='"$LAST_OFFSET"`"
    # Extract the update ID of the current message
    OFFSET="`echo "$MESSAGE" | sed 's/^.*"update_id":\([-0-9]\{1,10\}\),.*$/\1/;2d'`"
    # Extract the chat ID where the current message comes from
    CHAT="`echo "$MESSAGE" | sed 's/^.*"chat":{"id":\([-0-9]\{1,10\}\),.*$/\1/;1d'`"

    # If any of Rosa, Rous, ROSA and ROUS are found, we send the message
    if echo "$MESSAGE" | grep --quiet '"text":".*\(Rous\|ROUS\|Rosa\|ROSA\)'
    then
        curl "https://api.telegram.org/bot$BOTKEY/sendMessage" --data 'chat_id='"$CHAT" --data 'text=Rous mola' &> /dev/null
    fi

    # Finding a chat ID means that there has been an update
    if test "x$CHAT" != "x"
    then
        LAST_OFFSET="`expr $OFFSET + 1`"
    fi

    sleep 1s
done
