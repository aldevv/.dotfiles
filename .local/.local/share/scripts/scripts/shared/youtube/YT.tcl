
#!/usr/bin/expect --
#https://hsszyman.github.io/posts/browsing-youtube-with-dmenu/
set search [exec $env(UTILITIES)/youtube/fetch 1]
puts $search
# puts is simply an echo in the terminal, spawn runs the main command
eval spawn youtube-viewer --player=mpv $search
expect -re "=>>"
set out $expect_out(buffer)
set choice [exec $env(UTILITIES)/youtube/fetch $out $out]
#if choice is empty then dont send, end prog
set timeout -1
send -- "$choice \n"
sleep 5
set player_running [exec $env(UTILITIES)/youtube/playerRunning.sh ]
while {$player_running==0} {
    sleep 10
    set player_running [exec $env(UTILITIES)/youtube/playerRunning.sh ]
}
send -- "q\n"
exit
#expect {
      #"=>> Select one or more videos to play (:h for help)" {
            #set player_running [exec $([[ -z $(ps xhc | grep mpv) ]] && echo 1 || echo 0) ]
            #if {[player_running]!=1} {send "q\r"; exit}
      }
      #"root@$LinuxMachine's password:" {
            #send "root123\r"
            #expect "[root@Client_FC12_172_85 ~]#"
            #send "ls\r"
            #exp_continue
            # the exp_continue simply waits for the same prompt options once again
      #}
}
#exec runs a command and saves its output
#eval concatenates all of its arguments into a single string, and runs them
#expect_out(buffer) saves all output until it finds latest
# expect pattern https://person.hst.aau.dk/magnus/EDB/expect_tutorialnotes3.pdf
