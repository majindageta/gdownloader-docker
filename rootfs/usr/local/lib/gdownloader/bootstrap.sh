#!/bin/sh

prepare_state() {
    config_dir=$1
    output_dir=$2
    default_config=$3

    mkdir -p "$config_dir" "$output_dir"
    [ -w "$config_dir" ] || {
        echo "Directory is not writable: $config_dir" >&2
        return 1
    }
    [ -w "$output_dir" ] || {
        echo "Directory is not writable: $output_dir" >&2
        return 1
    }

    config_file="$config_dir/config.json"
    if [ -f "$config_file" ] && ! jq -e . "$config_file" >/dev/null 2>&1; then
        backup="$config_file.corrupt-$(date +%Y%m%d%H%M%S)-$$"
        mv "$config_file" "$backup"
        echo "Invalid config moved to $backup" >&2
    fi

    [ -f "$config_file" ] || cp "$default_config" "$config_file"
}

require_runtime() {
    app_launcher=$1
    shift

    [ -x "$app_launcher" ] || {
        echo "Missing application launcher: $app_launcher" >&2
        return 1
    }

    for command_name in "$@"; do
        command -v "$command_name" >/dev/null 2>&1 || {
            echo "Missing runtime command: $command_name" >&2
            return 1
        }
    done
}
