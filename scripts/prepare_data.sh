#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

#/ Usage: bash prepare_data.sh
#/ Description: Prepares the data for the experiment.
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
	locate_self
	cd $PARENT_DIR

	datadir=$(cat .data_dir)

	# Split the training audio
	train_audio=$datadir/train/audio/eng
	train_tab=${datadir}/train/sad/eng
	local_data=data
	local_train=data/train
	for channel in A B C D E F G H src; do
		# make the directories for holding the snippets
		for class in NS NT S RX; do 
			mkdir -p $local_train/$channel/$class
		done
		# make the snippets for each channel
		for audiofile in $train_audio/$channel/*.flac; do
			echo -n $audiofile"..."
			name=$(basename $audiofile)
			name_wo_ext=${name%.*} # non-greedy removal from end
			tabfile=$train_tab/$channel/$name_wo_ext.tab
			bash $SCRIPT_DIR/clip_helper.sh $audiofile $tabfile $local_train/$channel
			echo "done."
		done
	done

fi

