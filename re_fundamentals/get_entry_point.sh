#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <ELF file>" >&2
    exit 1
fi

file_name="$1"

if [ ! -f "$file_name" ]; then
    echo "Error: File '$file_name' does not exist." >&2
    exit 1
fi

elf_magic=$(od -An -tx1 -N4 -- "$file_name" | tr -d '[:space:]')

if [ "$elf_magic" != "7f454c46" ]; then
    echo "Error: File '$file_name' is not a valid ELF file." >&2
    exit 1
fi

elf_header=$(readelf -h -- "$file_name") || exit 1

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if [ ! -f "$script_directory/messages.sh" ]; then
    echo "Error: messages.sh was not found." >&2
    exit 1
fi

magic_number=$(printf '%s\n' "$elf_header" | awk '/^[[:space:]]*Magic:/{sub(/^[[:space:]]*Magic:[[:space:]]*/, ""); print; exit}')
class=$(printf '%s\n' "$elf_header" | awk -F: '/^[[:space:]]*Class:/{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}')
data=$(printf '%s\n' "$elf_header" | awk -F: '/^[[:space:]]*Data:/{sub(/^[^:]*:[[:space:]]*/, ""); print; exit}')
entry_point_address=$(printf '%s\n' "$elf_header" | awk -F: '/^[[:space:]]*Entry point address:/{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}')

case "$data" in
    *little\ endian*) byte_order="Little Endian" ;;
    *big\ endian*)    byte_order="Big Endian" ;;
    *)                byte_order="$data" ;;
esac

source "$script_directory/messages.sh"
display_elf_header_info
