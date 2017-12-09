#!/usr/bin/env bash
set -euo pipefail

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

	stage=2


	train_audio=$datadir/train/audio/eng
	train_tab=${datadir}/train/sad/eng
	local_data=data
	local_train=data/train
	channels="A B C D E F G H src"
	classes="NS NT S RX"
	used_classes="NS NT S"


	if [ $stage -le 1 ]; then
		# Split the training audio

		for channel in $channels; do
			( # Run each channel in a background task to speed up the work.

			# Make the directories for each class
			for class in $classes; do 
				mkdir -p $local_train/$channel/$class
			done
			for audiofile in $train_audio/$channel/*.flac; do
				name=$(basename $audiofile)
				name_wo_ext=${name%.*} # non-greedy removal from end
				tabfile=$train_tab/$channel/$name_wo_ext.tab
				bash $SCRIPT_DIR/clip_helper.sh $audiofile $tabfile $local_train/$channel
				echo "$audiofile done" # Progress indicator
			done
			) &
		done
	fi

	# Join all the snippets again but now one we get one audio file per channel and used class
	if [ $stage -le 2 ]; then
		for channel in $channels; do
			for class in $used_classes; do
				# Start out with small amount of silence
				sox -n -b 16 -r 16000 -c 1 $local_train/$channel/$class.wav trim 0 0.1
				for file in $local_train/$channel/$class/*.wav; do
					sox $local_train/$channel/$class.wav $file $local_train/$channel/_$class.wav
					mv $local_train/$channel/_$class.wav $local_train/$channel/$class.wav
				done
			done
		done
	fi
fi

