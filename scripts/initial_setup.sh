#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

#/ Usage: bash inital_setup.sh KALDI_ROOT RATS_DATA
#/ Description: Runs the initial experiment setup given a path 
#/   to a working kaldi installation and the DARPA RATS data.
#/ Examples: bash initial_setup.sh /opt/tools/kaldi /opt/data/DARPA_RATS/data
#/ Options:
#/   --help: Display this help message
usage() { grep '^#/' "$0" | cut -c4- ; exit 0 ; }
expr "$*" : ".*--help" > /dev/null && usage

locate_self() {
	# Locate this script.
	readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	readonly PARENT_DIR="$SCRIPT_DIR"/..
}

copy_from_existing_experiment() {
	local readonly origin="$KALDI_ROOT"/egs/sre08/v1/
	for dir in sid steps utils; do
		if [ -e "$dir" ]; then 
			if [ "$(readlink -- "$dir")" = "$origin"/$dir ]; then
				echo "Symlink '$dir' exits and is correct. Skipping it."
				continue
			fi
			echo "FATAL: '$dir' exists but is not a symlink pointing to the correct location."
			exit 1
		fi
			
		ln -s "$origin"/$dir $dir
	done

	for file in path.sh cmd.sh; do
		if [ -e "$file" ]; then
			if [ ! -f "$file" ]; then
				echo "FATAL: $file exists but is not a file."
				exit 1
			else
				echo "$file exists. We assume it is correct and skip it."
				continue
			fi
		else
			cp $origin/$file $file
			if [ $file == "path.sh" ]; then
				sed -i "s,export KALDI_ROOT=\`pwd\`/../../..,export KALDI_ROOT=$KALDI_ROOT," $file
			fi
		fi
	done

	echo $RATS_DATA > .data_dir
}


# Prevent execution when sourcing this script
if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
	if [[ $# -ne 2 ]]; then
		usage
	else
		KALDI_ROOT=$1
		RATS_DATA=$2
	fi

	locate_self
	cd "$PARENT_DIR"
	copy_from_existing_experiment
fi
