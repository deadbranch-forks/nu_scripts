# custom user banner

print $"Welcome to ( sys host | get hostname | str title-case ) on ( 
    sys host | get long_os_version ) \(( sys host | get kernel_version )\)

System information as:

    Uptime: ( sys host | get uptime )
    SSH Agent Status: ($env.SSH_AGENT_STATUS)

* Don't forget: The following modules are available to the user

- git-repo-init
- into mp3        - into wav
- into transcript - to file"