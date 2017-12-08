#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

#/ Usage: bash clip_helper.sh AUDIOFILE TABFILE OUTDIR
#/ Description: Creates snippets of AUDIOFILE for each segment in TABFILE
#/ 	and stores them in OUTDIR.
#/ Note: Also converts the output into .wav snippets.
#/ Examples: bash clip_helper.sh 10003_20706_alv_A.flac 10003_20706_alv_A.tab data/train/snippets
#/ Options:
#/   --help: Display this help message
usage() { grep '^#/' "$0" | cut -c4- ; exit 0 ; }
expr "$*" : ".*--help" > /dev/null && usage

locate_self() {
	# Locate this script.
	readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	readonly PARENT_DIR="$SCRIPT_DIR"/..
}

# Prevent execution when sourcing this script
if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
	if [[ $# -ne 3 ]]; then
		usage
	else
		audiofile=$1
		tabfile=$2
		outdir=$3
	fi

	locate_self
	cd $PARENT_DIR
	
	tabfile=10003_20706_alv_A.tab
	audiofile=somefile

	start_time_column=3
	end_time_column=4
	class_column=5

	cut -f$start_time_column,$end_time_column,$class_column $tabfile | xargs -I '{}' bash $SCRIPT_DIR/clip.sh $audiofile $outdir '{}'
fi

