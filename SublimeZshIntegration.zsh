alias -g st='"$(subl --command get_sublime_file_name; read sublime_file_name </tmp/sublime_file_name; print -n $sublime_file_name)"'
alias stx='subl --command get_sublime_file_name; read sublime_file_name </tmp/sublime_file_name; chmod +x "$sublime_file_name"'
alias -g ste='subl --command get_sublime_file_name; read sublime_file_name </tmp/sublime_file_name; print ${(qqq)sublime_file_name} |& tee /dev/tty |& wl-copy -n'
alias -g stn='subl --command get_sublime_file_name; read sublime_file_name </tmp/sublime_file_name; print ${sublime_file_name##*/} |& tee /dev/tty |& wl-copy -n'

goto_sublime_current_dir() {
    if [[ "$BUFFER" ]]; then
        unset __autosuggest_override_init
        zle accept-line
        return 0
    fi
    /opt/sublime_text/sublime_text --command get_sublime_folder_name
    [ -f /tmp/sublime_folder_name ] && read subldir </tmp/sublime_folder_name
    if [[ "${subldir}" != "${PWD}" ]]; then
        local precmd
        cd "$subldir" 2> /dev/null
        print -n "\e[?25l\033[F\r"
        for precmd in $precmd_functions
        do
            $precmd
        done
        zle reset-prompt
    else
        update_git_status_wrapper
    fi
    print -n '\e[?25h'
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
    /opt/sublime_text/sublime_text --command get_sublime_file_name
    [ -f /tmp/sublime_file_name ] && read sublime_file_name </tmp/sublime_file_name
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
    subl --command get_sublime_file_name
    _myfile=$(</tmp/sublime_file_name)
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
