#!/usr/bin/env -S nu --stdin
# add `use git_repo_init.nu *` to your config.nu file to use

def input_or_default [input: record] {
    if ($input.input | is-empty) {
        return $input.default
    }
    if ( $input.input | is-not-empty ) {
        return $input.input
    }
}

export def "git-repo-init" [] {

    let gitignore_file = ( $env.GIT_TEMPLATES_PATH | path join '.gitignore' )

    let repo_name = input_or_default ({   
        default: ( $env.PWD | path basename )
        input: ( input $"Repository name \(($env.PWD | path basename)\): " ) })

    let org_username = ^gh api user | from json | get login
    let org_list = ^gh api user/orgs | from json | get login | insert 0 $org_username

    let repo_owner = input_or_default ({
        default: ( $org_username )
        input: ( $org_list | input list "Choose an organization:" ) })


    let repo = ([$repo_owner "/" $repo_name] | str join)
    let url = (["git@github.com:" $repo ".git"] | str join)

    let template_choice = input_or_default ({
            default: "y"
            input: (input "Include .gitignore file? (y/n) [y]: ") })

    if ($template_choice == "y") {
        echo "Copying .gitignore to " $env.PWD "."
        cp $gitignore_file "./.gitignore"
        
        let edit_gitignore_choice = input_or_default ({
                default: "n"
                input: (input "Modify .gitignore before initial commit? (y/n) [n]: ") })
        
        if ($edit_gitignore_choice == "y") {
            echo "Opening editor..."
            nvim .gitignore
        }
    }


    git init -b main
    $"gh repo create ($repo) --source=. --remote=origin --private"
    ^gh repo create $repo --source=. --remote=origin --private
    echo "Repository " $repo " created."

    git remote set-url origin $url
    $"git remote set-url origin ($url)"
    echo "Remote repository initialization at http://www.github.com/" $repo " complete."
    git status

    let initial_commit_choice: string = input_or_default ( {
        default: "y"
        input: ( input "Do you want to push the contents of this directory to the new repository? (y/n) [y]: ") })

    if ($initial_commit_choice == "y") {
        git add .
        git status

        let continue_choice: string = input_or_default ({   
            default: "y"
            input: (input "Continue? (y/n) [y]: ") })
        
        if ($continue_choice == "y") {
            echo "Pushing repository content."
            git commit -m "Initial commit."
            git push origin main
        } else {
            git reset
        }
    } else {
        echo "Not pushing contents of this directory to the new repository."
    }

    (
    let repo_description: string = ^gh repo view --json description | from json | get description ;
    if ( $repo_description | is-empty ) {
        let description = (
            [
                ($env.PWD | path basename) 
                " configuration files. Originally located at: " 
                $env.PWD
                ] | str join
            )
        ^gh repo edit --description $description
    }
    )

}