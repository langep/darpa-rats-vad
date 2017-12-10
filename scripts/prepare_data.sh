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

	stage=3


	train_audio=$datadir/train/audio/eng
	train_tab=${datadir}/train/sad/eng
	local_data=data
	local_train=data/train
	channels="A B C D E F G H src"
	classes="NS NT S RX"
	used_classes="NS NT S"


	if [ $stage -eq 1 ]; then
		# Split the training audio into classes per channel

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

	# Join all the snippets again into a few files per class per channel
	if [ $stage -eq 2 ]; then
		for channel in $channels; do
			( # Run each channel in a background task to speed up the work
			for class in $used_classes; do
				if [ $class == "NT" ]; then
					# 'NT' class is used to mark non-transmitted regions during push-to-talk
					# simulation. The original data and channel G do not have it.
					if [ $channel == "G" ] || [ $channel == "src" ]; then
						continue
					fi 
				fi
				# Start out with small amount of silence
				sox -n -b 16 -r 16000 -c 1 $local_train/$channel/$class.1.wav trim 0 0.1
				counter=1
				fcounter=1
				for file in $local_train/$channel/$class/*.wav; do
					if [ $counter -ge 2000 ]; then 
						counter=0
						fcounter=$((fcounter+1))
						sox -n -b 16 -r 16000 -c 1 $local_train/$channel/$class.$fcounter.wav trim 0 0.1
					fi

					sox $local_train/$channel/$class.$fcounter.wav $file $local_train/$channel/_$class.$fcounter.wav
					mv $local_train/$channel/_$class.$fcounter.wav $local_train/$channel/$class.$fcounter.wav
					echo $file >> $local_train/$channel/$class.done
					counter=$((counter+1))

				done
			done
			) &
		done
	fi

	# Remove old snippets
	if [ $stage -eq 3 ]; then
		for channel in $channels; do
			for class in $used_classes; do
				rm -r $local_train/$channel/$class/
				mkdir -p $local_train/$channel/$class/
			done
		done
	fi

	# Break down the files into 60 second snippets
	if [ $stage -eq 4 ]; then
		for channel in $channels; do
			( # Run this in the background
			for class in $used_classes; do
				if [ $class == "NT" ]; then
					# 'NT' class is used to mark non-transmitted regions during push-to-talk
					# simulation. The original data and channel G do not have it.
					if [ $channel == "G" ] || [ $channel == "src" ]; then
						continue
					fi 
				fi
				for file in $local_train/$channel/$class.*.wav; do
					name=$(basename $file)
					name_wo_ext=${name%.*} # non-greedy removal from end
					sox $file $local_train/$channel/$class/$name_wo_ext.%1.wav trim 0 60 : newfile : restart
					echo $file >> $local_train/$channel/$class.split.done
				done
			done
			) &
		done
	fi

	if [ $stage -eq 5 ]; then
		for channel in $channels; do
			mkdir -p S/$channel NS/$channel 
			if [ $channel != "G" && $channel != "src" ]; then
				mkdir -p NT/$channel
			fi
			for class in $used_classes; do
				if [ $channel == "G" || $channel == "src" ] && [ $class = "NT" ]; then
					continue
				fi
				basedir=`pwd`
				for file in $local_train/$channel/$class/*.wav; do
					name=$(basename $file)
					name_wo_ext=${name%.*}
					echo $name_wo_ext\t$basedir/$file >> $class/$channel/wav.scp1
					echo $name_wo_ext\t$name_wo_ext >> $class/$channel/utt2spk1
				done
				cat $class/$channel/wav.scp1 | sort > $class/$channel/wav.scp
				rm $class/$channel/wav.scp1 
				cat $class/$channel/utt2spk1 | sort > $class/$channel/utt2spk
				rm $class/$channel/utt2spk1
			done
		done
	fi

fi

