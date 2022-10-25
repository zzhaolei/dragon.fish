status is-interactive || exit

set --global __dragon_vcs _dragon_vcs_$fish_pid
function $__dragon_vcs --on-variable _dragon_vcs
    commandline --function repaint
end

function __dragon_vcs --on-event fish_prompt
    set --query _dragon_pwd || _dragon_pwd

    command kill $_dragon_last_pid 2>/dev/null

    set --query _dragon_skip_git_prompt && set _dragon_vcs && return

    fish --private --command "
        set --local prefix (set_color normal)'('
        set --local suffix (set_color normal)')'
        set --local branch (command git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if test -z \"\$branch\"
            return
        end
        set branch (set_color green)\$branch
        set --local dirty ''
        set --local dirty_symbol '*'
        if test (command git status --porcelain --show-stash | count) -ne 0
            set dirty (set_color red)\$dirty_symbol
        else if test (command git rev-list --count --left-right @{upstream}...@ 2>/dev/null | string replace -r '\s+' '+' | math 2>/dev/null) -ne 0
            set dirty (set_color yellow)\$dirty_symbol
        else if test (command git stash list | count) -ne 0
            set dirty (set_color blue)\$dirty_symbol
        end

        set --universal _dragon_vcs \"\$prefix\$branch\$dirty\$suffix \"(set_color normal)
    " &

    set --global _dragon_last_pid (jobs --last --pid)
end

function _dragon_pwd --on-variable PWD --on-variable _dragon_ignored_git_paths
    set --local git_root (command git --no-optional-locks rev-parse --show-toplevel 2>/dev/null)
    if set --query git_root[1] && ! contains -- $git_root $_dragon_ignored_git_paths
        set --erase _dragon_skip_git_prompt
    else
        set --global _dragon_skip_git_prompt
    end

    set --global _dragon_pwd (set_color -o blue)(basename (prompt_pwd))(set_color normal)
end

function _dragon_venv --on-event fish_postexec
    set --query VIRTUAL_ENV_DISABLE_PROMPT
    or set --universal VIRTUAL_ENV_DISABLE_PROMPT true

    set _dragon_venv
    if set --query VIRTUAL_ENV
        set venv (string replace -r '.*/' '' -- $VIRTUAL_ENV)
        set --global _dragon_venv (set_color 808080)"$venv"(set_color normal)
    end
end

function _dragon_cmd_duration --on-event fish_postexec
    test "$CMD_DURATION" -lt 1000 && set _dragon_cmd_duration && return

    set --local secs (math --scale=1 $CMD_DURATION/1000 % 60)
    set --local mins (math --scale=0 $CMD_DURATION/60000 % 60)
    set --local hours (math --scale=0 $CMD_DURATION/3600000)

    set --local tooks
    test $hours -gt 0 && set --local --append tooks $hours"h"
    test $mins -gt 0 && set --local --append tooks $mins"m"
    test $secs -gt 0 && set --local --append tooks $secs"s"

    set --global _dragon_cmd_duration (set_color 808080)$tooks(set_color normal)
end

function _dragon_mode --on-event fish_postexec
    # readonly directory
    set -f group_id
    switch (uname -s)
        case Darwin
            set group_id (stat -f "%g" .)
        case '*'
            set group_id (stat -c "%g" .)
    end

    if test $group_id -ne (id -g $USER)
        set --global _dragon_mode (set_color --bold red)'[R]'(set_color normal)
        return
    end

    set _dragon_mode
    set -l mode (echo -ns (fish_default_mode_prompt) | string split -f1 ' ' | string trim -c ' ')
    if test -n "$mode"
        # 去除左右的颜色符号，如果字符为 [I] 则不显示
        if test (echo $mode | string sub -s 10 -e 12) = '[I]'
            return
        end
        set --global _dragon_mode $mode
    end
end

function _dragon_fish_exit --on-event fish_exit
    set --erase _dragon_vcs
end
