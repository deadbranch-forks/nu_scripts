
export def "into wav" [conversion_parameters?: record<sample_rate: int>]: string -> string {

    ## File operations
    ##
    let file: string = $in 
    let file_info: record = get-audio-info $file | first

    let input_file: record  = $file
        | path parse
        | insert filepath { ( $file | path expand ) }

    let output_filepath = $input_file.parent 
        | path join ( $input_file.stem | append ".wav" | str join )


    ## Sample rate operations
    ##    
    let parameter_record = (
        if ($conversion_parameters | is-empty ) { 
            { sample_rate: 16000 }
         }
        else { 
            ($conversion_parameters | default 16000 sample_rate) 
            }
        )
    let sample_rate: int = prevent-upsampling {
        # Use prevent-upsampling to prevent upsampling the output file if the
        # input file has a sample rate lower than the max desired.
        max-rate: ( $parameter_record.sample_rate | into int ), 
        input: ( $file_info.sample_rate | into int )
        }


    ## Conversion operations
    ##
    # Run ffmpeg and then output the filename so it can be part of the next pipe input.
    let conversion_result = if not ($input_file.filepath | path exists) {
        do { 
        ^ffmpeg -ar $sample_rate -ac 1 $output_filepath -i $input_file.filepath
        | complete 
        }
    }

    if ($output_filepath | path exists) {
        $output_filepath
    }
}


def get-audio-info [filepath] {
    ^ffprobe -v quiet -print_format json -show_streams $filepath
        | from json
        | get streams
        | where codec_type == audio
        | select codec_name sample_fmt sample_rate channels duration tags
}

def prevent-upsampling [sample_rates: record<max-rate: int, input: int>] {
    if ($sample_rates.input > $sample_rates.max-rate) {
        $sample_rates.max-rate
    } else {
        $sample_rates.input
    }
}

export def "into transcript" [whisper_options?: record]: {

    let pipe_input: string = $in

    ## Default values
    ##
    # transcript_path - a temporary directory to store json transcripts
    #
    let default_values: record = {
        transcript_path: "F:/whisper.cpp/transcriptions",
        model_filepath: "F:/M/models-speech-to-text/ggml-large-v3-turbo-q5_0.bin",
        threads: 10
    }

    ## Parameter parsing
    ##
    # Define an empty record so we can use default values in a later step
    #
    let input_options = if ($whisper_options | is-empty) {
        {}
    } else {
        $whisper_options
    }

    let options: record = $input_options
        | default $default_values.transcript_path transcript_path
        | default $default_values.model_filepath model_filepath
        | default $default_values.threads threads


    ## Filename operations
    ##
    let input_file: record = ( 
        $pipe_input
            | path parse
            | insert filepath { ( $pipe_input | path expand ) }
        )

    let output_filepath = ( 
        $options.transcript_path 
            | path join $input_file.stem
            # | append '.json'
            # | str join                
    )
    let output_file = (
        $output_filepath 
            | path parse
            | insert filepath { ( $output_filepath | append '.json' | str join | path expand ) }
            | insert transcript_path { ( $output_filepath | path expand ) }
    )

    ## Conversion operations
    ##
    let conversion_result = if not ($output_file.filepath | path exists) {
        do { 
            ^whisper --threads $options.threads -fa --language en -m $options.model_filepath  --output-json --output-file ( $output_file.transcript_path ) -f $input_file.filepath
            | complete
        }
    }
    if ($output_file.filepath | path exists) {
        open $output_file.filepath
            | to json
            | from json
            | $in.transcription
            | get text
            | str join
    }
    # let conversion_process = do {
    #     # ^whisper --threads $options.threads -fa --language en -d 10000 --output-json --output-file $output_file.filepath -f $input_file.filepath 
    #         # | complete
    #     ^whisper --threads $options.threads -fa --language en -m $options.model_filepath  --output-json --output-file ( $output_file.transcript_path ) -f $input_file.filepath
    #         | complete
    # }


    # let output_results = if ($conversion_process.exit_code == 0) {
    #     open $output_file.filepath
    #         | to json
    #         | from json
    #         | $in.transcription
    #         | get text
    #         | str join
    # } else {
    #     let error_details = $conversion_process.stderr | str join
    #     let error_message = ($conversion_process.exit_code | match $in {
    #         1 => {"General error: The `whisper` command encountered an unexpected issue."},
    #         2 => {"File not found: Ensure that the input file path is correct."},
    #         3 => {"Invalid model file: Check if the model filepath is correct and the file exists."},
    #         _ => {$"Unknown error with exit code { $conversion_process.exit_code }."}
    #     })

    #     error make {
    #         msg: $error_message
    #         label: {
    #             text: "Conversion Process Failed"
    #         }
    #         help: ( $"Error Details:\n($error_details)\n\nPossible Solutions:\n- Verify the input file path.\n- Check the model filepath and ensure the model file exists.\n- Review the `whisper` command options for correctness." )
    #     }
    # }

    # $output_file.filepath | path exists1
    # $output_file.filepath | path exists
        # open $output_file.filepath 
        #     | to json 
        #     | from json
    # $output_results

    }
    
