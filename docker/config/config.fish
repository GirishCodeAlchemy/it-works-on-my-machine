# Sample config.fish

# Set the prompt
set -g fish_prompt "Hello, Welcome to Fish Shell> "

# Add custom aliases
alias ll 'ls -l'
alias gs 'git status'

function fish_prompt
    set -l git_branch (git branch ^/dev/null | sed -n '/\* /s///p')
    echo -n (whoami)'@'(hostname)':'(prompt_pwd)'{'"$git_branch"'} $ '
end