#compdef wd.sh

CONFIG=$HOME/.warprc

local -a main_commands
main_commands=(
    add:'Adds the current working directory to your warp points'
    #add'\!':'Overwrites existing warp point' # TODO: Fix
    rm:'Removes the given warp point'
    ls:'Outputs all stored warp points'
    show:'Outputs warp points to current directory'
)

local -a points
i=1
while read line
do
    s=$(awk "{ gsub(/\/Users\/$USER|\/home\/$USER/,\"~\"); print }" <<< $line)
    points[i]=$s

    i="$(( $i+1 ))"
done < $CONFIG

_wd() 
{
    # init variables
    local curcontext="$curcontext" state line
    typeset -A opt_args

    # init state
    _arguments \
        '1: :->command' \
        '2: :->argument'

    case $state in
        command)
            #_describe -t main-commands 'main commands' main_commands && ret=0
            _describe -t warp-points 'warp points' points && ret=0
            #_arguments '1:command:(${(k)points})'
            compadd "$@" add rm ls show
            ;;
        argument)
            case $words[2] in
                rm|add!)
                    _describe -t warp-points 'warp points' points && ret=0
                    #compadd "$@" ${(k)points}
                    ;;
                *)
            esac
    esac
}

_wd "$@"

# Local Variables:
# mode: Shell-Script
# sh-indentation: 2
# indent-tabs-mode: nil
# sh-basic-offset: 2
# End:
# vim: ft=zsh sw=2 ts=2 et
