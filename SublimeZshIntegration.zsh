case $OSTYPE in
(darwin*)
    __subl_file_path="$TMPDIR/sublime_file_name"
    ;;
(linux-gnu)
    __subl_file_path="$XDG_RUNTIME_DIR/sublime_file_name"
    ;;
(*)
    printf "Your platform is not supported. Please open an issue"
    return 1
    ;;
esac

ST_ALIAS=${ST_ALIAS:-st}
typeset -gi ST_ALIAS_LENGTH=${#ST_ALIAS}
typeset -gi ST_ALIAS_LENGTH_EXT=$(( ST_ALIAS_LENGTH + 1))

alias -g $ST_ALIAS='"$(cat $__subl_file_path)"'
alias ${ST_ALIAS}+='chmod +x "$(cat $__subl_file_path)"'
alias ${ST_ALIAS}-='chmod -x "$(cat $__subl_file_path)"'
alias -g ${ST_ALIAS}n='read sublime_file_name < $__subl_file_path; print ${sublime_file_name##*/} |& tee /dev/tty |& wl-copy -n'
alias -g ${ST_ALIAS}e='read sublime_file_name < $__subl_file_path; print ${sublime_file_name} |& tee /dev/tty |& wl-copy -n'

st_helper() {
    if [[ "${LBUFFER: -$ST_ALIAS_LENGTH}" == "$ST_ALIAS" ]]; then
        local file
        read file < $__subl_file_path
        LBUFFER="${LBUFFER[1,-$ST_ALIAS_LENGTH_EXT]}$file "
        return 0
    fi
    LBUFFER+=" "
    return 0
}
zle -N st_helper
bindkey -e " " st_helper

__goto_sublime_current_dir() {
    if [[ "$BUFFER" ]]; then
        zle accept-line
        return 0
    fi
    if [[ -f "$__subl_file_path" ]]; then
        local __dir __file
        read __file < "$__subl_file_path"
        __dir="${__file%/*}"
        [[ "${__dir}" != "${PWD}" ]] && cd "$__dir"
        local precmd
        for precmd in $precmd_functions
        do
            $precmd
        done
        zle reset-prompt
    fi
}
zle -N __goto_sublime_current_dir
bindkey -e "^M" __goto_sublime_current_dir

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

${ST_ALIAS}save() {
    [[ -f "$__subl_file_path" ]] && read sublime_file_name < "$__subl_file_path" || return 1
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

${ST_ALIAS}del() {
    local sublime_file_name _ans _reply
    [[ -f "$__subl_file_path" ]] && read sublime_file_name < "$__subl_file_path" || return 1
    print "Do you want to delete this file: $(_colorizer $sublime_file_name)"
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
        rm $sublime_file_name
    fi
    print
    return 0
}
