#!/usr/bin/env bash
# Author: pll2121
set -euo pipefail

# Use clip_helper.sh instead of calling this file directly.

#/ Usage: bash clip.sh AUDIOFILE OUTDIR CLIPINFO
#/ Description: Creates single snippet from AUDIOFILE into OUTDIR/<class> according to 
#/ 	CLIPINFO. CLIPINFO is formated as "<start-time-sec>	<end-time-sec> <class>".
#/ Note: Also converts the output into .wav snippets.
#/ Examples: bash clip_helper.sh 10003_20706_alv_A.flac 10003_20706_alv_A.tab data/train/snippets
#/ Options:
#/   --help: Display this help message
usage() { grep '^#/' "$0" | cut -c4- ; exit 0 ; }
expr "$*" : ".*--help" > /dev/null && usage

# Prevent execution when sourcing this script
if [[ "${BASH_SOURCE[0]}" = "$0" ]]; then
	if [[ $# -ne 3 ]]; then
		usage
	fi

	audiofile=$1
	outdir=$2
	# Process args from xargs
	args=($3)
	start_time=${args[0]}
	end_time=${args[1]}
	class=${args[2]}
	# Determine clip filename
	name=$(basename $audiofile)
	name_wo_ext=${name%.*}
	clip_name=$name_wo_ext"_"$class"_"${start_time//./-}".wav"

	sox $audiofile $outdir/$class/$clip_name trim $start_time =$end_time
fi