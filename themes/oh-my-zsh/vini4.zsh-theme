#########################################
##       vinizap - theme for zsh        ##
##  based on Comfyline - theme for zsh  ##
# Author: vinizap ---------------------  #
# Original Author: not pua ( imnotpua )  #

# make prompt work without oh-my-zsh
setopt PROMPT_SUBST
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8 



# default segment seperators
if [[ $COMFYLINE_SEGSEP == "" ]]; then
    COMFYLINE_SEGSEP='\ue0b4'
fi

if [[ $COMFYLINE_SEGSEP_REVERSE == "" ]]; then
    COMFYLINE_SEGSEP_REVERSE='\ue0b6'
fi

# date and time formats 
if [[ $COMFYLINE_DATE_FORMAT == "" ]]; then
    COMFYLINE_DATE_FORMAT="%A, %e %B %Y"
fi

if [[ $COMFYLINE_TIME_FORMAT == "" ]]; then
    COMFYLINE_TIME_FORMAT="%l:%M %p"
fi

# default light theme 
if [[ $RETVAL_RANK == "" ]]; then
    RETVAL_RANK=1  
fi
if [[ $BASEDIR_RANK == "" ]]; then
    BASEDIR_RANK=2   
fi
if [[ $GIT_RANK == "" ]] then
    GIT_RANK=3
fi
if [[ $VENV_RANK = "" ]]; then
    VENV_RANK=4
fi
# if [[ $DIR_RANK == "" ]]; then
#     DIR_RANK=-4
# fi
if [[ $DATE_RANK == "" ]]; then
    DATE_RANK=-2
fi
if [[ $TIME_RANK == "" ]]; then
    TIME_RANK=-1
fi
# if [[ $USER_RANK == "" ]] then
#     USER_RANK=-1
# fi

# default colors
if [[  $RETVAL_b == "" ]]; then
    RETVAL_b="#8a8bd8"  
fi
if [[  $RETVAL_f == "" ]]; then
    RETVAL_f="#61355c" 
fi
if [[  $BASE_b == "" ]]; then
    BASE_b="#b3b5fb"
fi
if [[  $BASE_f == "" ]]; then
    BASE_f="#4a4b87"
fi
if [[  $USER_b == "" ]]; then
    USER_b="#f8bbe5"
fi
if [[  $USER_f == "" ]]; then
    USER_f="#874c80"
fi
if [[  $GIT_b == "" ]]; then
    GIT_b="#f6b3b3"
fi
if [[  $GIT_f == "" ]]; then
    GIT_f="#d95353"
fi
if [[  $GIT_CLEAN_b == "" ]]; then
    GIT_CLEAN_b="#b3f58c"
fi
if [[  $GIT_CLEAN_f == "" ]]; then
    GIT_CLEAN_f="#568459"
fi
if [[  $DIR_b == "" ]]; then
    DIR_b="#e1bff2"
fi
if [[  $DIR_f == "" ]]; then
    DIR_f="#844189"
fi
if [[  $VENV_b == "" ]]; then
    VENV_b="#a8ddf9"
fi
if [[  $VENV_f == "" ]]; then
    VENV_f="#0066a4"
fi
if [[  $BAT_b == "" ]]; then
    BAT_b="#b3b5fb"
fi
if [[  $BAT_f == "" ]]; then
    BAT_f="#4a4b87"
fi
if [[  $DATE_b == "" ]]; then
    DATE_b="#f8bbe5"
fi
if [[  $DATE_f == "" ]]; then
    DATE_f="#874c80"
fi
if [[  $TIME_b == "" ]]; then
    TIME_b="#e1bff2"
fi
if [[  $TIME_f == "" ]]; then
    TIME_f="#844189"
fi

# basic functions

#function takes 4 arguments, background, foreground, text and rank (for edge cases)
function create_segment(){
    if [[ $4 -lt $RIGHTMOST_RANK ]]; then
        local segment="%F{$1}$COMFYLINE_SEGSEP_REVERSE"
        echo -n "$segment%K{$1}%F{$2} $3 " 
    elif [[ $4 -gt $LEFTMOST_RANK ]]; then
        local segment="%K{$1}$COMFYLINE_SEGSEP "
        echo -n "$segment%F{$2}$3%F{$1} " 
    elif [[ $4 -eq $RIGHTMOST_RANK ]]; then
	if [[ $COMFYLINE_NO_START -eq 1 ]]; then
	    local segment="%F{$1}$COMFYLINE_SEGSEP_REVERSE"
	    echo -n "$segment%K{$1}%F{$2} $3" 
	else
	    local segment="%F{$1}$COMFYLINE_SEGSEP_REVERSE"
	    echo -n "$segment%K{$1}%F{$2} $3 %k%F{$1}$COMFYLINE_SEGSEP" 
	fi
    elif [[ $4 -eq $LEFTMOST_RANK ]]; then
	if [[ $COMFYLINE_NO_START -eq 1 ]]; then
	    local segment="%K{$1} " 
            echo -n "$segment%F{$2}$3%F{$1} " 
	else
	    local segment="%F{$1}$COMFYLINE_SEGSEP_REVERSE%K{$1} "
	    echo -n "$segment%F{$2}$3%F{$1} " 
	fi
    fi
	
}
###  explanation: creates segment seperator with new bg but fg as old bg. 
###               then prints contents in new fg and prepares for next fg as current bg

# segment functions
function retval(){
    if [[ $COMFYLINE_RETVAL_NUMBER -eq 0 ]]; then
        # Assuming 0 is the success return value
        symbol="\UF8FF" 
    elif [[ $COMFYLINE_RETVAL_NUMBER -eq 2 ]]; then
        symbol="%(?..✘ %?)"
    elif [[ $COMFYLINE_RETVAL_NUMBER -eq 1 ]]; then
        symbol="%?"
    else
        symbol="%(?..✘)"
    fi
    create_segment $RETVAL_b $RETVAL_f $symbol $RETVAL_RANK
}

function basedir(){
        create_segment $BASE_b $BASE_f "${PWD##*/}" $BASEDIR_RANK
}

function username(){
    create_segment $USER_b $USER_f "%n" $USER_RANK
}

function dir(){
    if [[ $COMFYLINE_FULL_DIR -eq 1 ]]; then
        symbol="%d"
    else
        symbol="%~"
    fi
    create_segment $DIR_b $DIR_f $symbol $DIR_RANK
}

# variables to set git_prompt info and status
ZSH_THEME_GIT_PROMPT_PREFIX=" \ue0a0 "
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY=""
ZSH_THEME_GIT_PROMPT_CLEAN=""
ZSH_THEME_GIT_PROMPT_ADDED=" ✚"
ZSH_THEME_GIT_PROMPT_MODIFIED=" ±"
ZSH_THEME_GIT_PROMPT_DELETED=" \u2796"
ZSH_THEME_GIT_PROMPT_UNTRACKED=" !"
ZSH_THEME_GIT_PROMPT_RENAMED=" \u21b7"
ZSH_THEME_GIT_PROMPT_UNMERGED=" \u21e1"
ZSH_THEME_GIT_PROMPT_AHEAD=" \u21c5"
ZSH_THEME_GIT_PROMPT_BEHIND=" \u21b1"
ZSH_THEME_GIT_PROMPT_DIVERGED=" \u21b0"

# Improved gitrepo function
function gitrepo(){
    if [ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ]; then
        local branch_name=$(git rev-parse --abbrev-ref HEAD)
        local git_status=""
        if [[ $(git status --porcelain) ]]; then
            # Add symbols to show dirty state, you can customize these further as needed
            git_status="$ZSH_THEME_GIT_PROMPT_MODIFIED"
        fi
        local full_git_prompt="$ZSH_THEME_GIT_PROMPT_PREFIX$branch_name$git_status$ZSH_THEME_GIT_PROMPT_SUFFIX"

        # Check if the repository is clean or dirty
        if [[ -z $git_status ]]; then
            create_segment $GIT_CLEAN_b $GIT_CLEAN_f "$full_git_prompt" $GIT_RANK
        else
            create_segment $GIT_b $GIT_f "$full_git_prompt" $GIT_RANK
        fi
    fi
}


function tmuxseession() {
    if tmux ls &> /dev/null; then
        info=$(tmux display-message -p '#I #W')
      else 
        info=""
    fi
        create_segment $DATE_b $DATE_f $info $DATE_RANK
}

function currtime() {
    if tmux ls &> /dev/null; then
        info=$(tmux display-message -p '#S')
        # info="%D{$COMFYLINE_TIME_FORMAT}"
      else 
        info=""
    fi
        create_segment $TIME_b $TIME_f $info $TIME_RANK
}

function endleft(){
    echo -n "%k$COMFYLINE_SEGSEP%f"
}

function venv(){
    if [ -n "$VIRTUAL_ENV" ]; then
        create_segment $VENV_b $VENV_f ${VIRTUAL_ENV:t:gs/%/%%} $VENV_RANK
    fi
}
# parse variables

# segments=("retval" "basedir" "username" "dir" "gitrepo" "venv" "currtime" "tmuxseession")
segments=("retval" "basedir" "gitrepo" "venv" "currtime" "tmuxseession")
# segment_ranks=($RETVAL_RANK $BASEDIR_RANK $USER_RANK $DIR_RANK $GIT_RANK $VENV_RANK $TIME_RANK $DATE_RANK)
segment_ranks=($RETVAL_RANK $BASEDIR_RANK $GIT_RANK $VENV_RANK $TIME_RANK $DATE_RANK)

# split into left and right

left_prompt=()
right_prompt=()
left_ranks=()
right_ranks=()
for ((i=1;i<=${#segments[@]};i++)); do
    if [[ segment_ranks[$i] -gt 0 ]]; then
        left_prompt+=(${segments[$i]}) 
        left_ranks+=(${segment_ranks[$i]}) 
    elif [[ segment_ranks[$i] -lt 0 ]]; then
        right_prompt+=(${segments[$i]})
        right_ranks+=(${segment_ranks[$i]#-})
    fi
done

# sort the prompts according to ranks and find the leftmost and rightmost
# I use the traditional iterative method to find max/min and using count-sort for sorting

LEFTMOST_RANK=100
declare -A sorted_left
for ((i=1;i<=${#left_prompt[@]};i++)); do
    if [[ $left_ranks[$i] -lt $LEFTMOST_RANK ]]; then LEFTMOST_RANK=$left_ranks[$i] fi
    sorted_left[$left_ranks[$i]]="$left_prompt[$i]"
done

RIGHTMOST_RANK=100
declare -A sorted_right
for ((i=1;i<=${#right_prompt[@]};i++)); do
    if [[ $right_ranks[$i] -lt $RIGHTMOST_RANK ]]; then RIGHTMOST_RANK=$right_ranks[$i] fi
    sorted_right[$right_ranks[$i]]="$right_prompt[$i]"
done
((RIGHTMOST_RANK*=-1))


# finally make_prompt which makes prompts
make_left_prompt(){
    for ((j = 1; j <= ${#left_prompt[@]}; j++)); do
        type $sorted_left[$j] &>/dev/null && $sorted_left[$j] 
    done
}

make_right_prompt(){
    for ((j = ${#right_prompt[@]}; j>0; j--)); do
        type $sorted_right[$j] &>/dev/null && $sorted_right[$j]
    done
}

export PROMPT='%{%f%b%k%}$(make_left_prompt)$(endleft) '
export RPROMPT='      %{%f%b%k%}$(make_right_prompt)'    # spaces left so that hiding is triggered

if [[ $COMFYLINE_NEXT_LINE_CHAR == "" ]]; then
    COMFYLINE_NEXT_LINE_CHAR='➟'
fi

if [[ $COMFYLINE_NEXT_LINE_CHAR_COLOR == "" ]]; then
    COMFYLINE_NEXT_LINE_CHAR_COLOR="grey"
fi

next_line_maker(){
    echo -n "%F{$COMFYLINE_NEXT_LINE_CHAR_COLOR}$COMFYLINE_NEXT_LINE_CHAR %f"    
}

# setting up typing area
if [[ COMFYLINE_START_NEXT_LINE -eq 1 ]]; then

PROMPT=$PROMPT'
'$(next_line_maker)


elif [[ COMFYLINE_NO_GAP_LINE -eq 1 ]]; then
else

    PROMPT='
'$PROMPT

fi

