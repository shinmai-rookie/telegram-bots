# json.sed: sed script that processes JSON files and partially produces a
#     shell script to assign its members to shell variables
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

# NOTES
#
# The seemingly redundant `b TAG; :TAG' helps cleaning the `t buffer': the `t'
# command jumps if there has been a successful substitution since the last line
# was read or the last jump was done, so by jumping, we avoid previous
# replacements interfering with it
#
# The `t' command is used because some commands use previous and following
# characters for the pattern; without the jumps, those characters would not
# match the same pattern


# We append a global prefix for everything
1 s/^/"json":/


1,$ {
    b STEP_0
    # 0) Prefetch the next line if this one is deemed incomplete
    #   A line is deemed incomplete if it doesn't end with `,' or `}'
    :STEP_0

    $! { /[},][ 	]*$/ ! { N; s/\n//; b STEP_0; } }


    b STEP_1
    # 1) Escape `%' into `%%%'
    #   `%' will be used as a escape character inside strings
    :STEP_1

    s/%/%%%/g


    b STEP_2
    # 2) Escape backslashes
    #   This may be unneeded
    :STEP_2

    s/\\\\/%\\%/g


    b STEP_3
    # 3) Escape simple quotation marks
    #   Needed to make 4) unambiguous
    :STEP_3

    s/'/%'%/g


    b STEP_4
    # 4) Escape double quotation marks inside strings
    #   This helps to match strings, which are sequences of characters without
    #   `"' inside them
    :STEP_4

    s/\\"/%''%/g


    b STEP_5
    # 5) Escape underscores
    #   This are used outside strings for opening and closing quotation marks
    #   It may be unneeded
    :STEP_5

    s/_/%_%/g


    b STEP_6
    # 6) Add underscores to quotation marks to distinguish the opening
    #   quotation marks from the closing ones
    :STEP_6

    s/^[ 	\n]*"/_"/g
    s/\([:,{\[]\)[ 	\n]*"/\1_"/g
    s/"[ 	\n]*\([]:,}]\)/"_\1/g


    b STEP_7
    # 7) Escape the characters `,', `.', `{', `}', `[' and `]'
    #   They're escaped surrounding them with `%'
    :STEP_7

    s/_"\([^"]*\)\([^%]\)\([],.{}\[]\)\([^%]\)\([^"]*\)"_/_"\1\2%\3%\4\5"_/g
    t STEP_7


    b STEP_8
    # 8) Start a new lexical block
    #   This marks the beginning of a new object
    #   In the third case, it's a named object; the other two are members of
    #   an array
    :STEP_8

    s/^[ 	]*{/\nSTART\n/g
    s/\([,\[]\)[ 	]*{/\1\nSTART\n/g
    s/_"\([^"]*\)"_[ 	]*:[ 	]*{/\nSTART _"\1"_\n/g
    t STEP_8


    b STEP_9
    # 9) End a lexical block
    #   This marks the end of an object
    :STEP_9

    s/}[ 	]*$/\nLESS\n/g
    s/}[ 	]*\([,}]\)/\nLESS\n\1/g
    s/}[ 	]*\]/\nLESS\n\]/g

    t STEP_9


    b STEP_10
    # 10) Replace `:' with bash assignments
    :STEP_10

    s/_"\([^"]*\)"_[ 	]*:[ 	]*/\1=/g


    b STEP_11
    # 11) Replace `[' and `]' with `START_ARRAY' and `END_ARRAY'
    #    This helps the shell part of this program to name and enumerate its
    #    members
    :STEP_11

    :STEP_11_A
    s/\[[ 	]*$/\nSTART_ARRAY\n/g
    s/\[[ 	]*\([^%]\)/\nSTART_ARRAY\n\1/g
    t STEP_11_A

    :STEP_11_B
    s/^[ 	]*\]/\nEND_ARRAY\n/g
    s/\([^%]\)[ 	]*\]/\1\nEND_ARRAY\n/g
    t STEP_11_B


    b STEP_12
    # 12) Replace commas outside strings with newlines
    :STEP_12

    s/^[ 	]*,/\n/g
    s/,[ 	]*$/\n/g
    s/\([^%]\),\([^%]\)/\1\n\2/g


    b STEP_13
    # 13) Un-escape backslashes inside strings
    :STEP_13

    s/%\\%/\\\\/g

    b STEP_14
    # 14) Un-escape the double quotation marks used for strings
    :STEP_14

    s/_"/"/g
    s/"_/"/g


    b STEP_15
    # 15) Un-escape the double quotation marks inside strings
    :STEP_15

    s/%''%/\\"/g


    b STEP_16
    # 16) Un-escape the other characters
    :STEP_16

    s/%\(.\)%/\1/g
}
