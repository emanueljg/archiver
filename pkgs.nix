{ yt-dlp, jq, writeShellApplication, ... }:
let

  writeArchiveScript =
    { name
    , obj
    , src
    , customFlags ? ""
    ,
    }: writeShellApplication {
      inherit name;
      runtimeInputs = [ yt-dlp jq ];
      text = ''
        obj='${obj}'
        src='${src}'
        archivalDate="$(TZ='UTC' date --iso-8601=seconds)"
        ytDlpVersion="${yt-dlp.name}"

        jq \
          -n \
          --arg 'src' "$src" \
          --arg 'ytDlpVersion' "$ytDlpVersion" \
          --arg 'archivalDate' "$archivalDate" \
          '$ARGS.named' > "$obj.json"
          
        yt-dlp \
          --write-link \
          --write-description \
          --write-thumbnail \
          --convert-thumbnails 'png' \
          --embed-thumbnail \
          --write-subs \
          --write-comments \
          --write-info-json \
          --embed-metadata \
          --cookies-from-browser 'firefox' \
          --merge-output-format 'mkv' \
          --paths "$obj" \
          --download-archive "$obj.archive" \
      '' + customFlags + ''
        "$src"
      '';
    };
in
rec {
  archiveCONAFAudio = writeArchiveScript {
    name = "archive-conaf-audio";
    obj = "Audio";
    src = "https://feeds.simplecast.com/dHoohVNH";
    customFlags = ''
      --playlist-reverse \
      --playlist-items "::-1" \
      --compat-options playlist-index \
      --parse-metadata "%(playlist_index)s:%(track_number)s" \
      --break-on-existing \
      -o '[%(playlist_index)s][%(upload_date>%Y-%m-%d)s] %(title)s [%(id)s]/%(title)s.%(ext)s' \
    '';
  };
  archiveCONAFVideo = writeArchiveScript {
    name = "archive-conaf-video";
    obj = "Video";
    src = "https://www.youtube.com/playlist?list=PLVL8S3lUHf0Te3TvS37LaF6dk4rhkc2gg";
    customFlags = ''
      -o '[%(upload_date>%Y-%m-%d)s] %(title)s [%(id)s]/%(title)s.%(ext)s' \
    '';
  };
  archiveCONAF = writeShellApplication {
    name = "archive-conaf";
    runtimeInputs = [
      archiveCONAFAudio
      archiveCONAFVideo
    ];
    # order here is very important due to audio script
    # will nearly always fail with non-zero exit code.
    text = ''
      archive-conaf-video
      archive-conaf-audio
    '';
  };
  default = archiveCONAF;

}
     
