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
    :I

    # 0) If this line is deemed incomplete, the next one is prefetched and
    #   joined to this one
    #   A line is incomplete if it doesn't end with `,' or `}'
    $! { /[},][ 	]*$/ ! { N; s/\n//; bI; } }

    # 1) Escape `%', which will be used as an escape character later on
    s/%/%%%/g

    # 2) Escape backslashes
    s/\\\\/%\\%/g

    # 3) Escape simple quotation marks
    s/'/%'%/g

    # 4) Escape double quotation marks
    #   We use two simple quotation marks so that we can use `[^"]*'
    #  (everything that is not `"') in the expressions below unambiguously,
    #  which would otherwise be very difficult (if not outright impossible)
    s/\\"/%''%/g

    # 5) Escape underscores
    #   This are used for opening and closing quotation marks
    #   MAY BE UNNEEDED
    s/_/%_%/g

    # 6) Replace opening and closing quotation marks to distinguish them
    s/^[ 	\n]*"/_"/g
    s/\([:,{\[]\)[ 	\n]*"/\1_"/g
    s/"[ 	\n]*\([]:,}]\)/"_\1/g

    # 7) Escape the characters `,', `.', `{', `}', `[' and `]'
    s/_"\([^"]*\)\([],.{}\[]\)\([^"]*\)"_/_"\1\2\3"_/g

    # 8) Remove unnecessary whitespace
    # TO BE THOUGHT

    # 9) Start a new lexical block
    s/^[ 	]*{/\nSTART\n/g
    s/_"\([^"]*\)"_[ 	]*:[ 	]*{/\nSTART _"\1"_\n/g
    s/\[[ 	]*{/\[\nSTART\n/g

    # 10) End a lexical block
    :H
    /}[ 	]*$/ { s/}[ 	]*$/\nLESS\n/; bH; }
    /}[ 	]*[,}]/ { s/}[ 	]*\([,}]\)/\nLESS\n\1/g; bH; }
    /}[ 	]*\]/ { s/}[ 	]*\]/\nLESS\n\]/; bH; }

    # 11) Replace `:' with bash assignments
    s/_"\([^"]*\)"_[ 	]*:[ 	]*/\1=/g

    # 12) Replace `[' and `]' with `(' and `)'
    #    This kinda handles nested arrays, though bash doesn't
    :J
    /\[[ 	]*$/ { s/\[[ 	]*$/\nSTART_ARRAY\n/g; bJ; }
    /\[[ 	]*[^%]/ { s/\[[ 	]*\([^%]\)/\nSTART_ARRAY\n\1/g; bJ; }

    :L
    /^[ 	]*\]/ { s/^[ 	]*\]/\nEND_ARRAY\n/g; bL; }
    /[^%][ 	]*\]/ { s/\([^%]\)[ 	]*\]/\1\nEND_ARRAY\n/g; bL; }

    # 13) Un-escape lexical double quotation marks
    s/_"/"/g
    s/"_/"/g

    # 14) Un-escape the string double quotation marks
    s/%''%/\\"/g

    # 15) Un-escape the other characters
    s/%\(.\)%/\1/g

    # 16) Replace commas with newlines
    s/^[ 	],/\n/g
    s/,[ 	]$/\n/g
    s/\([^%]\),\([^%]\)/\1\n\2/g
}

1,$ {
    # 17) Remove leading and trailing spaces
    s/^[ 	]*//g
    s/[ 	]*$//g
    
    # 18) Remove empty lines
    /^$/ d
}
