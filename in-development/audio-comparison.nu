def getAudioInfo [filepath] {
    ^ffprobe -v quiet -print_format json -show_streams $filepath
        | from json
        | get streams
        | where codec_type == audio
        | select codec_name sample_fmt sample_rate channels duration tags.encoder
}

def filepath_a = "F:/A/Audio - Music, 53 The Early Days - Hard/Darkest Hour/Undoing Ruin [2005]/02 - Convalescence.mp3" 
def filepath_b = `F:\File Cabinet\Torrents\Darkest Hour (USA)\01. Studio Albums\2005 - Undoing Ruin\03. Convalescence.mp3`
