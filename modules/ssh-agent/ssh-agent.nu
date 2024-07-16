do --env {
    let ssh_agent_file = (
        $env.HOMEDRIVE | path join $env.HOMEPATH | path join ".ssh" | path join "agent.env"
    )

    def --env load_agent_envs [file] {
        if ($file | path exists) {
            let agent_file_content = open ($ssh_agent_file)
            let ssh_agent_environment = $agent_file_content 
                | lines 
                | first 1
                | parse "SSH_AUTH_SOCK={SSH_AUTH_SOCK}; export SSH_AUTH_SOCK;" 
            load-env $ssh_agent_environment.0
        }
    }
    # load_agent_envs $ssh_agent_file

    if ($ssh_agent_file | path exists) == false {
        ssh-agent | save --force $ssh_agent_file
    }

    
    let ssh_agent_environment = open ($ssh_agent_file)
        | lines 
        | first 1
        | parse "SSH_AUTH_SOCK={SSH_AUTH_SOCK}; export SSH_AUTH_SOCK;" 
    load-env $ssh_agent_environment.0
    let agent_run_state = do { ^ssh-add -l | complete }
    let ssh = { 
        'socket': $env.SSH_AUTH_SOCK,
        'add-exit-code': $agent_run_state.exit_code
        }

    if $ssh.add-exit-code == 0 {
        print "Exit code 0.\nssh-agent has access to an active socket with authenticated keys"
        return
        # ssh-agent has access to an active socket
        # with authenticated identities
    }

    if $ssh.add-exit-code == 1 {
        print "Exit code 1\nssh-agent has access to an active socket but no keys added yet."
        return
        # ssh-agent has access to an active socket
        # but no keys have been added.
        # Will wait for the user to invoke `ssh` command, which adds the
        # identity to ssh-add automatically. 
    }

    # Otherwise, ssh-add exit code is 2
    # Meaning that either:
    # SSH_AUTH_SOCK is set to an invalid file,
    # or maybe ssh-agent isn't even running.
    # if $ssh.add-exit-code == 2 { }
    print $"Need to start agent. \nOld SSH_AUTH_SOCK: ($ssh.socket)"
    ssh-agent | save --force $ssh_agent_file
    let new_ssh_agent_environment = open ($ssh_agent_file)
        | lines 
        | first 1
        | parse "SSH_AUTH_SOCK={SSH_AUTH_SOCK}; export SSH_AUTH_SOCK;" 
    load-env $new_ssh_agent_environment.0
    print $"New SSH_AUTH_SOCK: ($env.SSH_AUTH_SOCK)"

}