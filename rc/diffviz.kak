decl -hidden line-specs diff_column
decl -hidden str diff_reference

def -hidden diff-update-marks %{
    # assume "our" buffer and "diff_reference" buffer are setup properly by the
    # calling "public" command
    eval -save-regs 'tr' %{

        # write buffer contents to temp files
        reg t %sh{mktemp}
        reg r %sh{mktemp}

        echo -debug "tempfile (a): " %reg{t}
        echo -debug "tempfile (b): " %reg{r}

        write %reg{t}
        set-option buffer diff_column %val{timestamp} '9999999999999|E'
        add-highlighter -override buffer/showdiff flag-lines red diff_column

        eval -buffer %opt{diff_reference} %{
            write %reg{r}
            set-option buffer diff_column %val{timestamp} '9999999999999|E'
            add-highlighter -override buffer/showdiff flag-lines red diff_column
        }
        eval %sh{
            diff -c99999  "$kak_reg_r" "$kak_reg_t" \
            | awk -v empty="" -v buf_b="$kak_reg_percent" -v buf_a="$kak_opt_diff_reference" \
                'BEGIN {
                    buffer=empty;
                    ln=0;
                    ln_a=1;
                    ln_b=1;
                }
                /^\*\*\*/ { buffer=buf_a }
                /^---/    { buffer=buf_b }
                !/^\*\*\*|^---/ {
                    mark=empty;
                    change=substr($0,0,1);
                    if (change=="-")     mark="{red+b}-";
                    if (change=="+")     mark="{green+b}+";
                    if (change=="!")     mark="{yellow+b}!";
                    if (buffer == buf_a) ln=ln_a++;
                    if (buffer == buf_b) ln=ln_b++;

                    if (mark && buffer != empty) {
                        printf("echo -debug eval -buffer %s %{  set-option -add buffer diff_column %s|%s }\n", buffer, ln, mark)
                        printf("eval -buffer %s %{  set-option -add buffer diff_column %s|%s }\n", buffer, ln, mark)
                    }
                }'
        }

        nop %sh{rm "$kak_reg_t"}
        nop %sh{rm "$kak_reg_r"}

        # TODO: somehow keep views in sync
    }

}

def diff-buffers -docstring "highlight changes from other buffer to this one" \
    -params 1 -buffer-completion \
%{
    # TODO disallow comparing to own buffer
    set-option buffer diff_reference %arg{1}
    eval %sh{
        if [ "$kak_reg_percent" = "$1" ]; then
            echo echo -markup '{red+b}Cannot compare buffer to itself!'
        else
            echo 'diff-update-marks'
            echo 'hook -group showdiff buffer NormalIdle .* diff-update-marks'
            echo 'hook -group showdiff buffer InsertIdle .* diff-update-marks'
        fi
    }
}

def diff-git -docstring "compare to git base version" \
%{
    set-option buffer diff_reference  "*git-base-%reg{%}*"
    eval -save-regs c %{

        # trick future new client to rename itself on startup
        eval %sh{
            echo "hook -once global ClientCreate .* %{ rename-client diff_$kak_client }"
        }

        eval -draft %sh{
            reference="$(mktemp)"
            git show HEAD:./"$kak_reg_percent" > "$reference"
            orig_file="$kak_reg_percent"
            echo try "%{ delete-buffer! $kak_opt_diff_reference }"
            echo split-horizontal
            echo edit -readonly "$reference"
            echo rename-buffer -scratch "$kak_opt_diff_reference"

            echo set-option buffer readonly true

            # TODO shouldn't be necessary, but my version of kak-lsp
            # gets angry if I don't do it
            echo set-option buffer filetype "''"

            echo "eval %sh{rm $reference}"

            echo tmux-focus "$kak_client"
        }
    }

    diff-buffers %opt{diff_reference}
}

def diff-end -docstring "hide and reset diff view" %{
    remove-hooks buffer showdiff
    set-option buffer diff_column %val{timestamp}

    eval -save-regs c %{
        reg c %sh{echo diff_$kak_client}
        try %{ eval -client %reg{c} quit }
    }

    eval -buffer %opt{diff_reference} %{
        remove-hooks buffer showdiff
        set-option buffer diff_column %val{timestamp}
    }
    delete-buffer %opt{diff_reference}

    set-option buffer diff_reference ''
}
