do --env {

    # Common practice with bash is to export ssh-agent environmental variables to ~.ssh/
    let ssh_agent_file = $env.HOMEDRIVE | path join $env.HOMEPATH '.ssh' 'agent.env'
    if not ($ssh_agent_file | path exists) {
        run-external 'ssh-agent' | save --force $ssh_agent_file
    }

    let current_ssh_auth_sock = open ($ssh_agent_file)
        | lines 
        | first 1
        | parse "SSH_AUTH_SOCK={SSH_AUTH_SOCK}; export SSH_AUTH_SOCK;" 
    load-env $current_ssh_auth_sock.0

    # Given $env.SSH_AUTH_SOCK, ssh-add -l will tell us if no ssh-agent is running, if the
    # file socket path is valid, or if it has an authenticated key (no further action needed)
    let agent_run_state = do { ^ssh-add -l | complete } | get exit_code
    if $agent_run_state == 0 { 
        print "ssh-agent: active with authenticated identity." | return
    }
    elseif $agent_run_state == 1 {
        print "ssh-agent: active and waiting for user to authenticate." | return        
    }

    # Otherwise, ssh-add exit code is 2, Meaning that either:
    # SSH_AUTH_SOCK is set to an invalid file, or maybe ssh-agent isn't even running.
    # We need to spawn a new ssh-agent process here.
    run-external 'ssh-agent' | save --force $ssh_agent_file
    let new_auth_socket = open ($ssh_agent_file)
        | lines 
        | first 1
        | parse "SSH_AUTH_SOCK={SSH_AUTH_SOCK}; export SSH_AUTH_SOCK;" 
    load-env $new_auth_socket.0
    print $"ssh-agent: now active and waiting for user to authenticate."
}