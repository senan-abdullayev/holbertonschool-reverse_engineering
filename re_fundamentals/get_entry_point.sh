#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Error: Usage: $0 <ELF file>" >&2
    exit 1
fi

file_name="$1"

if [ ! -f "$file_name" ]; then
    echo "Error: File '$file_name' does not exist." >&2
    exit 1
fi

if ! elf_header=$(LC_ALL=C readelf -h "$file_name" 2>/dev/null); then
    echo "Error: File '$file_name' is not a valid ELF file." >&2
    exit 1
fi

magic_number=$(printf '%s\n' "$elf_header" |
    awk '/Magic:/ {
        for (i = 2; i <= NF; i++) {
            printf "%s%s", $i, (i < NF ? " " : "")
        }
        print ""
        exit
    }')

class=$(printf '%s\n' "$elf_header" |
    awk -F: '/Class:/ {
        gsub(/^[ \t]+|[ \t]+$/, "", $2)
        print $2
        exit
    }')

data=$(printf '%s\n' "$elf_header" |
    awk -F: '/Data:/ {
        sub(/^[^:]*:[ \t]*/, "")
        print
        exit
    }')

case "$data" in
    *little\ endian*)
        byte_order="little endian"
        ;;
    *big\ endian*)
        byte_order="big endian"
        ;;
    *)
        byte_order="$data"
        ;;
esac

entry_point_address=$(printf '%s\n' "$elf_header" |
    awk -F: '/Entry point address:/ {
        gsub(/^[ \t]+|[ \t]+$/, "", $2)
        print $2
        exit
    }')

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [ ! -f "$script_directory/messages.sh" ]; then
    echo "Error: messages.sh was not found." >&2
    exit 1
fi

source "$script_directory/messages.sh"
display_elf_header_info
