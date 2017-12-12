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

	stage=1

	if [ $stage -eq 1 ]; then
		mkdir -p test
		for channel in $channels; do
			mkdir -p $local_test/$channel
			for file in $test_audio/$channel/*.flac; do
				name=$(basename $file)
				name_wo_ext=${name%.*}
				tmp=${name_wo_ext%_*}
				lang=${tmp##*_}
				if [ $lang == "eng" ]; then
					sox $file $local_test/$channel/$name_wo_ext.wav
					echo -e $name_wo_ext"\t"$local_test/$channel/$name_wo_ext.wav >> test/wav.scp1
					echo -e $name_wo_ext"\t"$name_wo_ext >> test/utt2spk1
					cat test/wav.scp1 | sort > test/wav.scp
					rm test/wav.scp1 
					cat test/utt2spk1 | sort > test/utt2spk
					rm test/utt2spk1
					./utils/utt2spk_to_spk2utt.pl test/utt2spk > test/spk2utt

				fi
			done
		fi
	fi

	if [ $stage -eq 2 ]; then
		mkdir -p mfcc/$class/$channel
		local/make_mfcc_pitch.sh --nj $nj --cmd "$train_cmd" \
			test exp/make_mfcc $mfccdir/test
		sid/compute_vad_decision.sh --nj $nj --cmd "$train_cmd" \
				test exp/make_vad $vaddir/test
	fi


fi





