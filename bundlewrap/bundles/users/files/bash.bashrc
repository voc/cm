[ -z "$PS1" ] && return

__node_name="${node.name}"

<%text>
if [[ "$(id -u)" -eq 0 ]]
then
    export PS1='\[\e[1;34m\][\[\e[1;91m\]'"$__node_name"'\[\e[1;34m\]][\[\e[1;91m\]\u\[\e[1;34m\]@\[\e[1;91m\]$PWD\[\e[1;34m\]] > \[\e[0m\]'
else
    export PS1='\[\e[1;34m\][\[\e[1;32m\]'"$__node_name"'\[\e[1;34m\]][\[\e[1;32m\]\u\[\e[1;34m\]@\[\e[1;32m\]\w\[\e[1;34m\]] > \[\e[0m\]'
fi
unset PROMPT_COMMAND

if [[ -f "/etc/node.description" ]]
then
    echo
    cat "/etc/node.description"
    echo
fi

uptime
last | grep 'still logged in'

export HISTCONTROL=ignoredups
export HISTSIZE=50000
export HISTTIMEFORMAT="%d/%m/%y %T "
export SAVEHIST=50000
shopt -s checkjobs
shopt -s checkwinsize
shopt -s globstar
shopt -s histreedit

export LESS="-iRS -# 2"

export EDITOR=vim
export VISUAL=vim

alias ipb='ip -brief'
alias l='ls -lAh'
alias s='sudo -i'
alias v='vim -p'
alias journalctl='journalctl -a -o short-full'
</%text>
% for k, v in sorted(node.metadata.get('bash_aliases', {}).items()):
alias ${k}='${v}'
% endfor

rsback()
{
    for i
    do
        [ -e "$i" ] || { echo "ERROR: $i does not exist" >&2; continue; }
        printf 'rsync -zaP -e ssh %q ' '--rsync-path=sudo rsync'
        printf '%q:%q .' "${node.hostname}" "$(printf '%q' "$(readlink -e -- "$i")")"
        printf '\n'
    done
}
% for k, v in sorted(node.metadata.get('bash_functions', {}).items()):

${k}() {
    ${v}
}
% endfor