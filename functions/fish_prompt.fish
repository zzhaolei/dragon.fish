function fish_prompt
    # first store raw pipe status
    set --function _pipestatus $pipestatus

    set --local symbol_color $fish_color_cwd
    for i in $_pipestatus
        if test $i -ne 0
            set symbol_color red
            break
        end
    end

    set --local symbol (set_color -o $symbol_color)"❯"(set_color normal)

    echo -e "$_dragon_pwd $_dragon_vcs$symbol "(set_color normal)
end
