{ writeShellApplication
, lib
, yt-dlp
, jq
, writeTextFile
}: rec {
  writeCompatShellApplication =
    { name
    , text
    , runtimeInputs ? [ ]
    , compatText ? text
    }: writeShellApplication {
      inherit name text runtimeInputs;
      derivationArgs.passthru.originalText = writeTextFile {
        name = "${name}-text";
        text = ''
          #!/usr/bin/env bash

          ${compatText}
        '';
        executable = true;
      };
    };

  writeArchiveScript =
    { name
    , url
    , downloadDir
    , args ? ""
    }: writeCompatShellApplication {
      inherit name;
      runtimeInputs = [ yt-dlp jq ];
      text = ''
        download_dir='${downloadDir}'

        meta_path="$download_dir.meta.json"
        archive_path="$download_dir.archive.txt"

        url='${url}'

        archival_date="$(TZ='UTC' date --iso-8601=seconds)"
        yt_dlp_version="$(yt-dlp --version)"

        jq \
          -n \
          --arg 'url' "$url" \
          --arg 'ytDlpVersion' "$yt_dlp_version" \
          --arg 'archivalDate' "$archival_date" \
          '$ARGS.named' > "$meta_path"
          
        yt-dlp \
      '' + args + ''
        --paths "$download_dir" \
        --download-archive "$archive_path" \
        "$url"
      '';
    };
}

