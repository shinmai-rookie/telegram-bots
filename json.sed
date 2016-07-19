# 1)     %  -> %%%
#   First we escape OUR escape character, to remove any ambiguity
# 2)     \\ -> %\%
#   Then we escape JSON's escape character, to help in future changes
# 3)     \' -> %''%
#   We escape inner single quotes, to avoid ambiguities with 4)
# 4)     \" -> %'%
#   We then escape inner double quotes, to distinguish them from normal double
#   quotes
# 5)     _ -> %_%
#   We escape undescores to solve ambiguities with 5)
# 6)     {" -> {_"
#        ," -> ,_"
#   We change the opening quotation marks to distinguish them from the closing
#   ones
# 7)     _".*,.*"_ -> _".*%,%.*"
#        _".*:.*"_ -> _".*%:%.*"
#        _".*{.*"_ -> _".*%{%.*"
#        _".*}.*"_ -> _".*%}%.*"
#        _".*[.*"_ -> _".*%[%.*"
#        _".*].*"_ -> _".*%]%.*"
#   We escape characters inside strings that have a meaning outside them
# 8)     Remove unnecessary whitespace
# 9)     [^%]:{ -> {move the name to a special buffer, to be appended to all the properties}
# 10)    [^%]}  -> {take from the special buffer one level of nestedness}
# 11)    _".*"_: -> .*=
#   Take the quotation marks from the first part of the identifiers
# 12)    [^%][  -> (
#        [^%]]  -> )
#   For array support
# 13)    %. -> .
#   We then remove the escaping %


# We append a global prefix for everything
1 s/^/"json":/

1,$ {
    b STEP_0
    # 0) If this line is deemed incomplete, the next one is prefetched and
    #   joined to this one
    #   A line is incomplete if it doesn't end with `,' or `}'
    :STEP_0

    $! { /[},][ 	]*$/ ! { N; s/\n//; b STEP_0; } }


    b STEP_1
    # 1) Escape `%', which will be used as an escape character later on
    :STEP_1

    s/%/%%%/g


    b STEP_2
    # 2) Escape backslashes
    :STEP_2

    s/\\\\/%\\%/g


    b STEP_3
    # 3) Escape simple quotation marks
    :STEP_3

    s/'/%'%/g


    b STEP_4
    # 4) Escape double quotation marks
    #   We use two simple quotation marks so that we can use `[^"]*'
    #  (everything that is not `"') in the expressions below unambiguously,
    #  which would otherwise be very difficult (if not outright impossible)
    :STEP_4

    s/\\"/%''%/g


    b STEP_5
    # 5) Escape underscores
    #   This are used for opening and closing quotation marks
    #   MAY BE UNNEEDED
    :STEP_5

    s/_/%_%/g


    b STEP_6
    # 6) Replace opening and closing quotation marks to distinguish them
    :STEP_6

    s/^[ 	\n]*"/_"/g
    s/\([:,{\[]\)[ 	\n]*"/\1_"/g
    s/"[ 	\n]*\([]:,}]\)/"_\1/g

    b STEP_7
    # 7) Escape the characters `,', `.', `{', `}', `[' and `]'
    :STEP_7

    /_"[^"]*[^%][],.{}\[][^%][^"]*"_/ { s/_"\([^"]*\)\([^%]\)\([],.{}\[]\)\([^%]\)\([^"]*\)"_/_"\1\2%\3%\4\5"_/g; b STEP_7; }

    b STEP_8
    # 8) Remove unnecessary whitespace
    # TO BE THOUGHT
    :STEP_8

    b STEP_9
    # 9) Start a new lexical block
    :STEP_9

    /^[ 	]*{/                   { s/^[ 	]*{/\nSTART\n/g; b STEP_9; }
    /[,\[][ 	]*{/                   { s/\([,\[]\)[ 	]*{/\1\nSTART\n/g; b STEP_9; }
    /_"[^"]*"_[ 	]*:[ 	]*{/   { s/_"\([^"]*\)"_[ 	]*:[ 	]*{/\nSTART _"\1"_\n/g; b STEP_9; }

    b STEP_10
    # 10) End a lexical block
    :STEP_10

    /}[ 	]*$/ { s/}[ 	]*$/\nLESS\n/; b STEP_10; }
    /}[ 	]*[,}]/ { s/}[ 	]*\([,}]\)/\nLESS\n\1/g; b STEP_10; }
    /}[ 	]*\]/ { s/}[ 	]*\]/\nLESS\n\]/; b STEP_10; }

    b STEP_11
    # 11) Replace `:' with bash assignments
    :STEP_11

    s/_"\([^"]*\)"_[ 	]*:[ 	]*/\1=/g

    b STEP_12
    # 12) Replace `[' and `]' with `(' and `)'
    #    This kinda handles nested arrays, though bash doesn't
    :STEP_12

    :STEP_12_A
    /\[[ 	]*$/ { s/\[[ 	]*$/\nSTART_ARRAY\n/g; b STEP_12_A; }
    /\[[ 	]*[^%]/ { s/\[[ 	]*\([^%]\)/\nSTART_ARRAY\n\1/g; b STEP_12_A; }

    :STEP_12_B
    /^[ 	]*\]/ { s/^[ 	]*\]/\nEND_ARRAY\n/g; b STEP_12_B; }
    /[^%][ 	]*\]/ { s/\([^%]\)[ 	]*\]/\1\nEND_ARRAY\n/g; b STEP_12_B; }

    b STEP_13
    # 13) Replace commas with newlines
    :STEP_13

    s/^[ 	]*,/\n/g
    s/,[ 	]*$/\n/g
    s/\([^%]\),\([^%]\)/\1\n\2/g

    b STEP_14
    # 14) Un-escape lexical double quotation marks
    :STEP_14

    s/_"/"/g
    s/"_/"/g

    b STEP_15
    # 15) Un-escape the string double quotation marks
    :STEP_15

    s/%''%/\\"/g

    b STEP_16
    # 16) Un-escape the other characters
    :STEP_16

    s/%\(.\)%/\1/g
}
