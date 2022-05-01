alias -g st='"$(cat $XDG_RUNTIME_DIR/sublime_file_name)"'
alias st+='chmod +x "$(cat $XDG_RUNTIME_DIR/sublime_file_name)"'
alias st-='chmod -x "$(cat $XDG_RUNTIME_DIR/sublime_file_name)"'
alias -g stn='read sublime_file_name < $XDG_RUNTIME_DIR/sublime_file_name; print ${sublime_file_name##*/} |& tee /dev/tty |& wl-copy -n'
alias -g ste='read sublime_file_name < $XDG_RUNTIME_DIR/sublime_file_name; print ${sublime_file_name} |& tee /dev/tty |& wl-copy -n'

# navigate dirs with backspace/shift+backspace
setopt AUTO_PUSHD
typeset -a _dirstack
typeset -a mydirs
shift_backward() {
    # mydirs is not regulated when we push to the stack,
    # so we have to check for elements manually:
    [[ "${mydirs[-1]}" == "$PWD" ]] && mydirs[-1]=()
    [[  ${#mydirs} -lt 1 ]] && return
    print -n '\e[?25l'
    for (( i = 1; i <= ${#dirstack[@]}; i++ )) do
        if [[ "$dirstack[$i]" != "$_dirstack[$i]" ]]; then
            mydirs=()
            _dirstack=()
            print -n '\e[?25h'
            return
        fi
    done

    local preexec precmd
    for preexec in $preexec_functions
    do
        $preexec
    done
    _dirstack=("$PWD" "$_dirstack[@]")
    cd "${mydirs[-1]}" > /dev/null 2>&1
    mydirs[-1]=()
    for precmd in $precmd_functions
    do
        $precmd
    done
    zle reset-prompt
    print -n '\e[?25h'
    return 0
    }
zle -N shift_backward
bindkey '^]' shift_backward

typeset -gA __matchers=("\"" "\"" "'" "'" "[" "]" "(" ")" "{" "}")
backward-delete-char() {
    # goes back in the cd history
    if [[ -z "$BUFFER" ]]; then
        print -n '\e[?25l'
        for (( i = 1; i <= ${#dirstack[@]}; i++ )) do
            if [[ "$dirstack[$i]" != "$_dirstack[$i]" ]]; then
                mydirs=()
                break
            fi
        done
        [[ "${dirstack[1]}" == "$PWD" ]] && popd > /dev/null 2>&1
        [[  ${#dirstack} -lt 1 ]] && print -n '\e[?25h' && return
        [[ "${mydirs[-1]}" == "$PWD" ]] || mydirs+=("$PWD")
        local preexec precmd
        for preexec in $preexec_functions
        do
            $preexec
        done
        popd > /dev/null 2>&1
        _dirstack=($dirstack[@])
        for precmd in $precmd_functions
        do
            $precmd
        done
        zle reset-prompt
        print -n '\e[?25h'
        return 0
    fi

    if ((REGION_ACTIVE)) then
        if [[ $CURSOR -gt $MARK ]]; then
            BUFFER=$BUFFER[0,MARK]$BUFFER[CURSOR+1,-1]
            CURSOR=$MARK
        else
            BUFFER=$BUFFER[1,CURSOR]$BUFFER[MARK+1,-1]
        fi
        zle set-mark-command -n -1
    else
        if [[ "$BUFFER" == "${_ZSH_FILE_OPENER_CMD} " ]]; then
            printf "\033[J"
            zle .backward-delete-char
            zle .backward-delete-char
        else
            local left_char="${LBUFFER: -1}"
            local left_left_char="${LBUFFER: -2:1}"
            local right_char="${RBUFFER:0:1}"
            if [[ -n "$left_char" ]] && [[ -n "$right_char" ]] && [[ "${__matchers[$left_char]}" == "$right_char" ]]; then
                zle .delete-char
            elif [[ -n "$left_char" ]] && [[ -n "$left_left_char" ]] && [[ "${__matchers[$left_left_char]}" == "$left_char" ]]; then
                zle .backward-delete-char
            fi
            zle .backward-delete-char
        fi
    fi
    _zsh_highlight
}
zle -N backward-delete-char
bindkey "^?" backward-delete-char

goto_sublime_current_dir() {
    if [[ "$BUFFER" ]]; then
        unset __autosuggest_override_init
        zle accept-line
        return 0
    fi
    if [[ -f "$XDG_RUNTIME_DIR/sublime_file_name" ]]; then
        local subldir file
        read subldir < "$XDG_RUNTIME_DIR/sublime_file_name"
        file="${subldir%/*}"
        if [[ "${file}" != "${PWD}" ]]; then
            cd "$file"
            local precmd
            for precmd in $precmd_functions
            do
                $precmd
            done
            zle reset-prompt
        else
            gitstatus_query -t -0 -c update_git_status 'MY'
        fi
    fi
}
zle -N goto_sublime_current_dir
bindkey -e "^M" goto_sublime_current_dir

__add_goto_sublime_current_dir_to_zsh_autosuggest_clear_widgets() {
    (( ${+ZSH_AUTOSUGGEST_CLEAR_WIDGETS} )) && {
        ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=('goto_sublime_current_dir')
        add-zsh-hook -d precmd __add_goto_sublime_current_dir_to_zsh_autosuggest_clear_widgets
        add-zsh-hook -d preexec __remove_goto_sublime_current_dir
        unfunction __add_goto_sublime_current_dir_to_zsh_autosuggest_clear_widgets
        unfunction __remove_goto_sublime_current_dir
    }
}

__remove_goto_sublime_current_dir() {
    add-zsh-hook -d precmd __add_goto_sublime_current_dir_to_zsh_autosuggest_clear_widgets
    add-zsh-hook -d preexec __remove_goto_sublime_current_dir
    unfunction __add_goto_sublime_current_dir_to_zsh_autosuggest_clear_widgets
    unfunction __remove_goto_sublime_current_dir
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd __add_goto_sublime_current_dir_to_zsh_autosuggest_clear_widgets
add-zsh-hook preexec __remove_goto_sublime_current_dir

save() {
    [ -f "$XDG_RUNTIME_DIR/sublime_file_name" ] && read sublime_file_name < "$XDG_RUNTIME_DIR/sublime_file_name"
    if [[ "$sublime_file_name" == "/etc/doas.conf" ]]; then
        print "Cannot edit \033[32m\x1B[1m/etc/doas.conf\033[0m, you need to be root"
        return 1
    fi
    print -n "Saving \033[34m\x1B[1m${sublime_file_name##*/}\033[0m in "
    print "\033[32m\x1B[1m${sublime_file_name%/*}\033[0m"
    [ -f "$sublime_file_name" ] && prevperm=$(stat -c %a "$sublime_file_name") || prevperm="644"
    doas mkdir -p "${sublime_file_name%/*}" || return
    doas touch "$sublime_file_name"
    doas chmod 666 "$sublime_file_name"
    /opt/sublime_text/sublime_text --command save
    doas chmod $prevperm "$sublime_file_name"
}

stc() {
    local _myfile _ans _reply
    _myfile=$(< "$XDG_RUNTIME_DIR/sublime_file_name")
    print "Do you want to delete this file: $(_colorizer $_myfile)"
    echo -n "Continue? y or n? "
    until [[ ! -z $_ans ]]; do
        read -sk _reply
        case $_reply in
            [Yy]) _ans='yes' ;;
            [Nn]) _ans='no' ;;
        esac
    done
    if [[ $_ans == "yes" ]]; then
        subl --command close
        rm $_myfile
    fi
    print
    return 0
}
