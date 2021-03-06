#!/usr/bin/env bash
# Author: pll2121
set -euo pipefail

#/ Usage: bash make_train_set_vad_decisions.
#/ Description: Computes energy based VAD decisions for each channel and class in the training set. 
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
	source ./cmd.sh
	source ./path.sh

	vaddir=`pwd`/mfcc
	train_cmd="utils/run.pl"
	decode_cmd="utils/run.pl"
	nj=12

	channels="A B C D E F G H src"
	used_classes="NS NT S"

	for class in $used_classes; do
		for channel in $channels; do
			if [ $class == "NT" ]; then
				if [ $channel == "G" ] || [ $channel == "src" ]; then
					continue
				fi
			fi
			mkdir -p mfcc/$class/$channel
			sid/compute_vad_decision.sh --nj $nj --cmd "$train_cmd" \
   				$class/$channel exp/make_vad $vaddir/$class/$channel
		done
	done
fi





