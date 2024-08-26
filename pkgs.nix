{ yt-dlp, writeShellApplication, ... }:
let

  writeDownloadScript =
    { obj
    , src
    , customFlags ? ""
    ,
    }: writeShellApplication {
      runtimeInputs = [ yt-dlp ];
      text = ''
        obj='${obj}'
        src='${src}'
        echo "$src" > "$obj.source"
        echo "$(TZ='UTC' date --iso-8601=seconds)" > "$obj.date"

        yt-dlp \
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
{
  audio = writeDownloadScript {
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
  video = writeDownloadScript {
    obj = "Video";
    src = "https://www.youtube.com/playlist?list=PLVL8S3lUHf0Te3TvS37LaF6dk4rhkc2gg";
    customFlags = ''
      -o '[%(upload_date>%Y-%m-%d)s] %(title)s [%(id)s]/%(title)s.%(ext)s' \
    '';
  };

}
     
