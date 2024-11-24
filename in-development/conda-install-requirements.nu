let python: record<packages: record, channels: list<any>> = {
    packages: {
        python: "3.9"
    }
    channels: []
}

let dependancies: record<packages: record, channels: list<any>> = {
    packages: {
        transformers: "4.29.2"
        numba: ""
        inflect: ""
        pysoundfile: ""
    }
    channels: [
        "conda-forge"
    ]
}

let pytorch: record<packages: record, channels: list<any>>  = {
    packages: {
        pytorch: ""
        torchvision: ""
        torchaudio: ""
        "pytorch-cuda": "11.7"
    }
    channels: [
        pytorch nvidia
    ]
}

def createCondaRequirement [record] {
    let packages: record = $record  | get packages
    $packages | select 1
    # | each {|kv|
    #     $'($kv | describe)'    
    # }
}

createCondaRequirement $pytorch
