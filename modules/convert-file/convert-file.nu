# Accept either a binary stream (output of open) or table (output of ls)
# with-env {NU_LOG_LEVEL:DEBUG } { use std log }

# Expecting a list of files generated by `ls`.
# For each row, update the null rows with information gathered from ffprobe.
# Get a parsed json output from ffprobe and put it in file_info so we can manipulate it.
# The resulting table may contain one or two streams. If it's a video file, there's a 
# video and audio stream. The audio stream contains most of the information we're trying to get.
export def "media info from ls" []: table -> table {
    $in
    | insert audio_codec null
    | insert channels null
    | insert media_type null
    | insert sample_rate null
    | each {|row|
        let file_info = (
            open $row.name
            | ^ffprobe -v quiet -print_format json -show_streams -i pipe:0
            | from json
            | get streams
        )

        $row
        | update media_type ($file_info | first | get codec_type)
        | update sample_rate ($file_info
            | where {|x| $x.codec_type? == 'audio'} 
            | get sample_rate?.0
            | into int
        )
        | update channels ($file_info
            | where {|x| $x.codec_type? == 'audio'} 
            | get channels?.0 
            | into int
        )
        | update audio_codec ($file_info 
            | where {|x| $x.codec_type? == 'audio'} 
            | get codec_name?.0 
            | into string
        )
    }
}

export def "into mp3" [profile?]: table -> table {
    let column_name: string = 'mp3'    
    let mp3_profiles: table = [
        {profile_name: "voice_low_quality", sample_rate: 8000, bit_rate: 32},
        {profile_name: "voice_normal", sample_rate: 16000, bit_rate: 64},
        {profile_name: "music", sample_rate: 41100, bit_rate: 192}
    ] 
    
    let profile_name = if ($profile | is-empty) { 
        'voice_normal' 
    } else { $profile }

    let settings = $mp3_profiles | where {|x| $x.profile_name == $profile_name }

    $in 
    | media info from ls
    | insert $column_name null
    | each {|file|
        let display_options = ['-v' 'quiet']
        let input_options: list = ['-i' 'pipe:']
        let output_options =  [
            '-ar' ...$settings.sample_rate 
            '-ac' $file.channels
            '-ab' ([...$settings.bit_rate  'k'] | str join '')
            '-f' 'mp3'
            'pipe:'
        ]

        let final_command = [
            $display_options $input_options $output_options
        ] 
        | flatten
        # print $"|DEBUG| Constructed command: ($final_command)"

        $file 
        | update $column_name (
            open $file.name
            | ^ffmpeg ...$final_command
            | into binary
        )
        # print $"|INFO| File converted. Generated wav data for ($file.name)."
    }  
}

export def "into wav" []: table -> table {
    # Expecting a list of files generated by `ls`.
    $in 
    | media info from ls
    | insert wav null
    | each {|file|
        let display_options: list = ['-v' 'quiet']
        let input_options: list = ['-i' 'pipe:']
        let video_flags: list = (if ($file.media_type == 'video') {
            ['-vn' '-f' 'mov']
        } else { 
            [] 
        })

        let output_options: list =  [
            '-ar' '16000' 
            '-ac' '1'
            '-c:a' 'pcm_s16le'
            '-f' 'wav'
            'pipe:'
        ]

        let final_command: list = [
            $display_options $input_options $video_flags $output_options
        ]
        | flatten
        # print $"|DEBUG| Constructed command: ($final_command)"

        $file 
        | update wav (
            open $file.name
            | (^ffmpeg ...$final_command)
            | into binary
        )
        # print $"|INFO| File converted. Generated wav data for ($file.name)."
    }   
} 

export def "to file" []: table -> table {
    $in 
    | each {|file|
        let is_mp3 = $file | columns | any {|x| $x == 'mp3' }
        let is_wav = $file | columns | any {|x| $x == 'wav' }

        let output_file_extension: string = if ($is_mp3 == true) { 
            'mp3' 
        }
        else if ($is_wav == true) { 
            'wav' 
        }

        let output_file = ($file.name
            | path parse
            | [ $in.stem '.' $output_file_extension]
            | str join ""
        )
        if ($output_file | path exists) {
            # print $"|DEBUG| File exists. Skipped saving ($output_file)."
        }
        if (not ( $output_file | path exists )) {
            $file 
            | get $output_file_extension
            | save $output_file
            # print $"|INFO| File saved. Data written to file ($output_file)"
        }
        $output_file
    }
} 

# into transcript batch transcribes wav data to json using whisper.cpp
# Expects a table output from ls
#   Either a simple table of files.
#   (table<name: string, type: string, size: filesize, modified: date>)
#       - Use case: Designed to make using into transcript easy. Just 
#            `ls *.wav | into transcript` and everything gets converted. 
#       - In this case, non-wav files must be rejected from the table.
#   Or a table of files (from ls) including a column of binary wav data.
#   (table<name: string, type: string, size: filesize, modified: date, audio_codec: string, channels: int, media_type: string, sample_rate: int, wav: binary> (stream)
#       - In this case, for each row, we need to make extensive use of `mktemp` while interacting with
#           whisper.cpp because whisper doesn't accept piped inputs nor does it output json to a pipe.
export def "into transcript" []: table -> table {
    # TODO: Either detetct or allow the user to specify a profile string.
    let selected_profile = 'windows'
    let device_profiles = [[device, model_filepath, threads];
        ['windows' 'F:/M/models-speech-to-text/ggml-large-v3-turbo-q5_0.bin' 10]
        ['linux' '~/M/models-ggml.bin' 2]
    ]
    let device_setting = $device_profiles | where device == $selected_profile
    # TODO: Let the user pass a record of device settings, or just use the device_settings as default
    let setting = { 
        model_filepath: ($device_setting | get model_filepath).0,
        threads: ($device_setting | get threads).0 
    }

    # let wav_filepaths = ($in | each {|file| mktemp -t XXXXXXX.wav })

    # TODO Cleanup (delete all temporarily created files after)
    let file_list = ($in 
        | reject wav     
        # | insert wav_filepath { (mktemp -t XXXXXX.wav) }
        | insert wav_filepath { (mktemp XXXXXX.wav) }
        | insert transcript_filepath { (mktemp XXXXXXX.json) }
        # | insert transcript_filepath { (mktemp -t XXXXXXX.json) }
        | insert transcript null
    )
    

    # Extracate binary wav data for processing
    $in
    | enumerate
    | each {|row|
        let index: int = $row.index
        let filepath = $file_list | get $index | get wav_filepath
        
        $row.item | get wav | save --force $filepath #(mktemp XXXXXX.wav)
    }

    # Transcribe using whisper.cpp
    $file_list
    | update transcript {|file|
        let output_filepath = ($file | get transcript_filepath | path parse | get stem)

        # TODO: Convert the long string of whisper arguments into an array
        # let whisper_arguments = [
        #     '--no-prints'
        #     '--threads' $setting.threads
        #     '-fa'
        #     '--language en'
        #     '-m' $setting.model_filepath
        #     '--output-json'
        #     '--output-file' $output_filepath
        #     '-d' '10000'
        #     '-f' ($file | get wav_filepath)
        # ] | flatten
        # do {
        #     (^whisper ...$whisper_arguments)  | complete
        # }
        do {
            ^whisper --no-prints --threads $setting.threads -fa --language en -m $setting.model_filepath --output-json --output-file $output_filepath -d 10000 -f ($file | get wav_filepath)
            | complete
        }
        | if ($in.exit_code == 0) {
            let transcript_result = (
                open --raw ($file | get transcript_filepath)
                | from json
                | get transcription
            )
            rm ($file | get transcript_filepath)
            $transcript_result
        }
    } 
  
    # cleanup-temporary-files {file_data: $file_list, column_names: ['wav_filepath' 'transcript_filepath']}

    # $file_list
}

def cleanup-temporary-files [data: record] {
    $data.file_data | each {|row|
        do {
            rm ($row | get wav_filepath)
            rm ($row | get transcript_filepath)
        }
    }
}