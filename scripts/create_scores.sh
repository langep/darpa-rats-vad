#!/usr/bin/env bash
set -euo pipefail

#/ Usage: bash create_scores.sh
#/ Description: Produces scores for all run experiments.
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

	channels="A B C D E F G H src"
	used_classes="NS NT S"

	mkdir -p scores

	for channel in $channels; do
		python scripts/score.py ground_truth/ exp/test_$channel > scores/$channel.scores
		python scripts/score.py ground_truth/ exp/test_all_$channel > scores/all_$channel.scores
	done

	python scripts/score.py ground_truth/ exp/test_all > scores/all.scores
fi