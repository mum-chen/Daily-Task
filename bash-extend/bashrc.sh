# enable the xclip
if [ -x /usr/bin/xclip ]; then
    alias xc="xclip"
    alias xv="xclip -o"
    alias jx="pwd | xclip"
    alias jv="cd \`xv\`"
    if [ -x /usr/bin/realpath ]; then
        xf()
        {
            local filename="$1"
            realpath ${filename} | xclip
        }
    fi
fi
