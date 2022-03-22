if [ -d "$HOME/.local/Programs/rust/cargo/env" ]; then
    source "$HOME/.local/Programs/rust/cargo/env"
fi
alias psqlit='docker container exec -it covidalert_db_1 psql -U ale covidalert'
alias v="nvim"\
    sa='source createVenv'\
    sar='source installReq'

