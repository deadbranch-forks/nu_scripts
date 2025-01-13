export def "combine files" []: table -> string {
    $in
    | insert file_content null
    | each {|row|
        $row | update file_content (open $row.name)
    }
    | get file_content
    | str join '\n\n'
}