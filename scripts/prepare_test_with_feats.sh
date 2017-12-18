#!/usr/bin/env bash
set -euo pipefail

#/ Usage: bash prepare_test_with_feats.sh
#/ Description: Prepares the data for the test set including features and vad decisions.
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
	export LC_ALL=C
	source ./cmd.sh
	source ./path.sh

	datadir=$(cat .data_dir)

	train_cmd="utils/run.pl"
	nj=12

	channels="A B C D E F G H src"
	used_classes="NS NT S"


	test_audio=$datadir/dev-1/audio
	test_tab=$datadir/dev-1/sad
	local_test=data/test
	mfccdir=mfcc
	vaddir=mfcc

	stage=$1

	if [ $stage -le 1 ]; then
		mkdir -p test/all
		for channel in $channels; do
			mkdir -p $local_test/$channel
			mkdir -p test/$channel
			for file in $test_audio/$channel/*.flac; do
				name=$(basename $file)
				name_wo_ext=${name%.*}
				tmp=${name_wo_ext%_*}
				lang=${tmp##*_}
				if [ $lang == "eng" ]; then
					sox $file $local_test/$channel/$name_wo_ext.wav
					# For per channel evaluation
					echo -e $name_wo_ext"\t"$local_test/$channel/$name_wo_ext.wav >> test/$channel/wav.scp1
					echo -e $name_wo_ext"\t"$name_wo_ext >> test/$channel/utt2spk1
					# For combined model evaluation
					echo -e $name_wo_ext"\t"$local_test/$channel/$name_wo_ext.wav >> test/all/wav.scp1
					echo -e $name_wo_ext"\t"$name_wo_ext >> test/all/utt2spk1
				fi
			done
			# For per channel evaluation
			cat test/$channel/wav.scp1 | sort > test/$channel/wav.scp
			rm test/$channel/wav.scp1 
			cat test/$channel/utt2spk1 | sort > test/$channel/utt2spk
			rm test/$channel/utt2spk1
			./utils/utt2spk_to_spk2utt.pl test/$channel/utt2spk > test/$channel/spk2utt
		done
		# For combined model evaluation
		cat test/all/wav.scp1 | sort > test/all/wav.scp
		rm test/all/wav.scp1 
		cat test/all/utt2spk1 | sort > test/all/utt2spk
		rm test/all/utt2spk1
		./utils/utt2spk_to_spk2utt.pl test/all/utt2spk > test/all/spk2utt
	fi

	if [ $stage -le 2 ]; then
		for channel in $channels; do
			mkdir -p mfcc/test/$channel
			local/make_mfcc_pitch.sh --nj $nj --cmd "$train_cmd" \
				test/$channel exp/make_mfcc $mfccdir/test/$channel
			sid/compute_vad_decision.sh --nj $nj --cmd "$train_cmd" \
				test/$channel exp/make_vad $vaddir/test/$channel
		done

		local/make_mfcc_pitch.sh --nj $nj --cmd "$train_cmd" \
			test/all exp/make_mfcc $mfccdir/test/all
		sid/compute_vad_decision.sh --nj $nj --cmd "$train_cmd" \
			test/all exp/make_vad $vaddir/test/all
	fi

	if [ $stage -le 3 ]; then
		mkdir -p ground_truth
		for channel in $channels; do
			for file in $test_audio/$channel/*.flac; do
				name=$(basename $file)
				name_wo_ext=${name%.*}
				tmp=${name_wo_ext%_*}
				lang=${tmp##*_}
				tabfile=$name_wo_ext.tab
				if [ $lang == "eng" ]; then
					python scripts/tab_to_ground_truth.py $test_tab/$channel/$tabfile ground_truth $name_wo_ext
				fi
			done
		done
	fi

fi





