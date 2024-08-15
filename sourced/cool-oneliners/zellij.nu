#!/usr/bin/env -S nu --stdin

export def "parse zellij-sessions" [] {
    $in | parse -r '(?P<name>.*?) \[Created (?P<created>.+) ago](?: \()?(?P<state>.+?(?= ))?'
}

export def "filter active-sessions" [] {
    $in | filter { |session|
            $session.state =~ "EXITED"
        }
}   

# export def "zellij delete" [] {
#     $in | each { |session|
#             $"zellij delete-session ($session.name)"
#     }
# }
export def "zellij delete" [] {
    $in | each { |session|
            $session.name | ansi strip | ^zellij delete-session $in
    }
}