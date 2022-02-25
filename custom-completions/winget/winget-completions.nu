# Written by Genna

# Windows Package Manager
extern winget [
    --version(-v): bool, # Display the version of the tool
    --info: bool, # Display general info of the tool
    --help(-?): bool, # Display the help for this command
]

# Installs the given package
extern "winget install" [
    query?: string,
    --query(-q): string, # The query used to search for a package
    --manifest(-m): path, # The path to the manifest of the package
    --id: string, # Filter results by id
    --name: string, # Filter results by name
    --moniker: string, # Filter results by moniker
    --version(-v): string, # Use the specified version; default is the latest version
    --source(-s): string@"nu-complete winget install source", # Find package using the specified source
    --scope: string@"nu-complete winget install scope", # Select install scope (user or machine)
    --exact(-e): bool, # Find package using exact match
    --interactive(-i): bool, # Request interactive installation; user input may be needed
    --silent(-h): bool, # Request silent installation
    --locale: string@"nu-complete winget install locale", # Locale to use (BCP47 format)
    --log(-o): path, # Log location (if supported)
    --override: string, # Override arguments to be passed on to the installer
    --location(-l): path, # Location to install to (if supported)
    --force: bool, # Override the installer hash check
    --accept-package-agreements: bool, # Accept all licence agreements for packages
    --header: string, # Optional Windows-Package-Manager REST source HTTP header
    --accept-source-agreements: bool, # Accept all source agreements during source operations
    --help(-?): bool # Display the help for this command
]

# Shows information about a package
extern "winget show" [
    query?: string,
    --query(-q): string, # The query used to search for a package
    --id: string, # Filter results by id
    --name: string, # Filter results by name
    --moniker: string, # Filter results by moniker
    --version(-v): string, # Use the specified version; default is the latest version
    --source(-s): string@"nu-complete winget install source", # Find package using the specified source
    --scope: string@"nu-complete winget install scope", # Select install scope (user or machine)
    --exact(-e): bool, # Find package using exact match
    --interactive(-i): bool, # Request interactive installation; user input may be needed
    --silent(-h): bool, # Request silent installation
    --locale: string@"nu-complete winget install locale", # Locale to use (BCP47 format)
    --log(-o): path, # Log location (if supported)
    --override: string, # Override arguments to be passed on to the installer
    --location(-l): path, # Location to install to (if supported)
    --force: bool, # Override the installer hash check
    --accept-package-agreements: bool, # Accept all licence agreements for packages
    --header: string, # Optional Windows-Package-Manager REST source HTTP header
    --accept-source-agreements: bool, # Accept all source agreements during source operations
    --help(-?): bool, # Display the help for this command
]

# Manage sources of packages
extern "winget source" [
    --help(-?): bool # Display the help for this command
]

# Add a new source
extern "winget source add" [
    --name(-n): string, # Name of the source
    --arg(-a): string, # Argument given to the source
    --type(-t): string@"nu-complete winget source type", # Type of the source
    --header: string, # Optional Windows-Package-Manager REST source HTTP header
    --accept-source-agreements: bool, # Accept all source agreements during source operations
    --help(-?): bool # Display the help for this command
]

# List current sources
extern "winget source list" [
    --name(-n): string, # Name of the source
    --help(-?): bool # Display the help for this command
]

# Update current sources
extern "winget source update" [
    --name(-n): string, # Name of the source
    --help(-?): bool # Display the help for this command
]

# Remove current sources
extern "winget source remove" [
    --name(-n): string, # Name of the source
    --help(-?): bool # Display the help for this command
]

# Reset sources
extern "winget source reset" [
    --name(-n): string, # Name of the source
    --force: bool, # Forces the reset of the sources
    --help(-?): bool # Display the help for this command
]

# Export current sources
extern "winget source export" [
    --name(-n): string, # Name of the source
    --help(-?): bool # Display the help for this command
]

# Find and show basic info of packages
extern "winget search" [
    query?: string,
    --query(-q): string, # The query used to search for a package
    --id: string, # Filter results by id
    --name: string, # Filter results by name
    --moniker: string, # Filter results by moniker
    --tag: string, # Filter results by tag
    --command: string, # Filter results by command
    --source(-s): string@"nu-complete winget install source", # Find package using the specified source
    --count(-n): int, # Show no more than specified number of results
    --exact(-e): bool, # Find package using exact match
    --header: string, # Optional Windows-Package-Manager REST source HTTP header
    --accept-source-agreements: bool, # Accept all source agreements during source operations
    --help(-?): bool # Display the help for this command
]

# Display installed packages
#extern "winget list" [
#    query?: string,
#    --query(-q): string, # The query used to search for a package
#    --id: string, # Filter results by id
#    --name: string, # Filter results by name
#    --moniker: string, # Filter results by moniker
#    --tag: string, # Filter results by tag
#    --command: string, # Filter results by command
#    --source(-s): string@"nu-complete winget install source", # Find package using the specified source
#    --count(-n): int, # Show no more than specified number of results
#    --exact(-e): bool, # Find package using exact match
#    --header: string, # Optional Windows-Package-Manager REST source HTTP header
#    --accept-source-agreements: bool, # Accept all source agreements during source operations
#    --help(-?): bool # Display the help for this command
#]

# Display installed packages in a structured way.
def "winget list" [
    pos_query?: string,
    --query(-q): string, # The query used to search for a package
    --id: string, # Filter results by id
    --name: string, # Filter results by name
    --moniker: string, # Filter results by moniker
    --tag: string, # Filter results by tag
    --command: string, # Filter results by command
    --source(-s): string@"nu-complete winget install source", # Find package using the specified source
    --count(-n): int, # Show no more than specified number of results
    --exact(-e): bool, # Find package using exact match
    --header: string, # Optional Windows-Package-Manager REST source HTTP header
    --accept-source-agreements: bool, # Accept all source agreements during source operations
    --help(-?): bool # Display the help for this command
] {
    let flagify = { |name, value| nu-complete winget flagify $name $value }

    let command = ([
        "winget list"
        $pos_query,
        (do $flagify query $query)
        (do $flagify id $id)
        (do $flagify name $name)
        (do $flagify moniker $moniker)
        (do $flagify tag $tag)
        (do $flagify command $command)
        (do $flagify source $source)
        (do $flagify count $count)
        (do $flagify exact $exact)
        (do $flagify header $header)
        (do $flagify accept-source-agreements $accept-source-agreements)
    ] | str collect ' ')

    if $help {
        ^winget list -?
    } else {
        let output = (^$command | lines)
        let header = (
            $output | first
            | parse -r "(?P<name>Name\s+)(?P<id>Id\s+)(?P<version>Version\s+)(?P<available>Available\s+)?(?P<source>Source\s*)?"
            | first
        )
        let lengths = {
            name: ($header.name | str length),
            id: ($header.id | str length),
            version: ($header.version | str length),
            available: ($header.available | str length),
            source: ($header.source | str length)
        }
        $output | skip 2 | each { |it|
            let it = ($it | split chars)

            let available = if $lengths.available > 0 {
                (
                    $it | skip ($lengths.name + $lengths.id + $lengths.version)
                    | first $lengths.available | str collect | str trim
                )
            } else { "" }

            let source = if $lengths.source > 0 {
                (
                    $it | skip ($lengths.name + $lengths.id + $lengths.version + $lengths.available)
                    | str collect | str trim
                )
            } else { "" }

            {
                name: ($it | first $lengths.name | str collect),
                id: ($it | skip $lengths.name | first $lengths.id | str collect | str trim),
                version: ($it | skip ($lengths.name + $lengths.id) | first $lengths.version | str collect | str trim),
                available: $available,
                source: $source
            }
        }
    }
}

# Upgrades the given package
extern "winget upgrade" [
    query?: string,
    --query(-q): string, # The query used to search for a package
    --manifest(-m): path, # The path to the manifest of the package
    --id: string, # Filter results by id
    --name: string, # Filter results by name
    --moniker: string, # Filter results by moniker
    --version(-v): string, # Use the specified version; default is the latest version
    --source(-s): string@"nu-complete winget install source", # Find package using the specified source
    --exact(-e): bool, # Find package using exact match
    --interactive(-i): bool, # Request interactive installation; user input may be needed
    --silent(-h): bool, # Request silent installation
    --log(-o): path, # Log location (if supported)
    --override: string, # Override arguments to be passed on to the installer
    --location(-l): path, # Location to install to (if supported)
    --force: bool, # Override the installer hash check
    --accept-package-agreements: bool, # Accept all licence agreements for packages
    --header: string, # Optional Windows-Package-Manager REST source HTTP header
    --accept-source-agreements: bool, # Accept all source agreements during source operations
    --all: bool, # Update all installed packages to latest if available
    --help(-?): bool # Display the help for this command
]

# Uninstalls the given package
extern "winget uninstall" [
    query?: string@"nu-complete winget uninstall package name",
    --query(-q): string@"nu-complete winget uninstall package name", # The query used to search for a package
    --manifest(-m): path, # The path to the manifest of the package
    --id: string@"nu-complete winget uninstall package id", # Filter results by id
    --name: string@"nu-complete winget uninstall package name", # Filter results by name
    --moniker: string, # Filter results by moniker
    --version(-v): string, # Use the specified version; default is the latest version
    --source(-s): string@"nu-complete winget install source", # Find package using the specified source
    --exact(-e): bool, # Find package using exact match
    --interactive(-i): bool, # Request interactive installation; user input may be needed
    --silent(-h): bool, # Request silent installation
    --log(-o): path, # Log location (if supported)
    --help(-?): bool # Display the help for this command
]

# Helper to hash installer files
extern "winget hash" [
    file?: path, # File to be hashed
    --file(-f): path, # File to be hashed
    --msix(-m): bool, # Input file will be treated as msix; signature hash will be provided if signed
    --help(-?): bool # Display the help for this command
]

# Validates a manifest file
extern "winget validate" [
    manifest?: path, # The path to the manifest to be validated
    --manifest: path,  # The path to the manifest to be validated
    --help(-?): bool # Display the help for this command
]

# Open settings or set administrator settings
extern "winget settings" [
    --enable: string, # Enables the specific administrator setting
    --disable: string, # Disables the specific administrator setting
    --help(-?): bool # Display the help for this command
]

# Shows the status of experimental features
extern "winget features" [
    --help(-?): bool # Display the help for this command
]

# Exports a list of the installed packages
extern "winget export" [
    output?: path, # File where the result is to be written
    --output(-o): path, # File where the result is to be written
    --source(-s): string@"nu-complete winget install source", # Export packages from the specified source
    --include-versions: bool, # Include package versions in produced file
    --accept-source-agreements: bool, # Accept all source agreements during source operations
    --help(-?): bool # Display the help for this command
]

extern "winget import" [
    import-file?: path, # File describing the packages to install
    --import-file(-i): path, # File describing the packages to install
    --ignore-unavailable: bool, # Ignore unavailable packages
    --ignore-versions: bool, # Ignore package versions
    --accept-package-agreements: bool, # Accept all licence agreements for packages
    --accept-source-agreements: bool # Accept all source agreements during source operations
]

def "nu-complete winget install locale" [] {
    [
        "ar-SA","bn-BD","bn-IN","cs-CZ","da-DK","de-AT","de-CH","de-DE","el-GR",
        "en-AU","en-CA","en-GB","en-IE","en-IN","en-NZ","en-US","en-ZA","es-AR",
        "es-CL","es-CO","es-ES","es-MX","es-US","fi-FI","fr-BE","fr-CA","fr-CH",
        "fr-FR","he-IL","hi-IN","hu-HU","id-ID","it-CH","it-IT","jp-JP","ko-KR",
        "nl-BE","nl-NL","no-NO","pl-PL","pt-BR","pt-PT","ro-RO","ru-RU","sk-SK",
        "sv-SE","ta-IN","ta-LK","th-TH","tr-TR","zh-CN","zh-HK","zh-TW"
    ]
}

def "nu-complete winget install source" [] {
  ^winget source list | lines | skip 2 | split column ' ' | get column1
}

def "nu-complete winget install scope" [] {
  ["user", "machine"]
}

def "nu-complete winget source type" [] {
    ["Microsoft.PreIndexed.Package"]
}

def "nu-complete winget flagify" [name: string, value: any, --short(-s): bool] {
  let flag_start = if $short { '-' } else { '--' }
  if $value == $nothing || $value == $false {
    ""
  } else if $value == $true {
    $"($flag_start)($name)"
  } else {
    $"($flag_start)($name) ($value)"
  }
}

def "nu-complete winget uninstall package id" [] {
    ^winget export -s winget -o __winget-temp__.json | ignore
    let results = (open __winget-temp__.json | get Sources.Packages | first | get PackageIdentifier)
    rm __winget-temp__.json | ignore
    $results
}

def "nu-complete winget uninstall package name" [] {
    winget list structured | get Name | str trim | str find-replace "…" "..."
}