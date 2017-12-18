#!/usr/bin/env bash
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PARENT_DIR="$SCRIPT_DIR"/..

cd $PARENT_DIR

source ./cmd.sh
source ./path.sh

stage=$1

if [ $stage -le 1 ]; then
	sid/compute_vad_decision_gmm.sh --nj 10 --use_energy_vad false test/all exp/full_ubm_NS_all exp/full_ubm_S_all exp/full_ubm_NT_all exp/test_all exp/test_all

	channels="A B C D E F H"
	used_classes="NS NT S"
	for channel in $channels; do
		sid/compute_vad_decision_gmm.sh --nj 10 --use_energy_vad false test/$channel exp/full_ubm_NS_$channel exp/full_ubm_S_$channel exp/full_ubm_NT_$channel exp/test_$channel exp/test_$channel
	done

	# Not using NT model as we didn't train it for these channels
	channels="G src"
	used_classes="NS S"
	for channel in $channels; do
		sid/compute_vad_decision_gmm.sh --nj 10 --use_energy_vad false test/$channel exp/full_ubm_NS_$channel exp/full_ubm_S_$channel exp/test_$channel exp/test_$channel
	done
fi

if [ $stage -le 2 ]; then
	# Using joint model on individual channels to evaluate performance per channel
	channels="A B C D E F H"
	used_classes="NS NT S"
	for channel in $channels; do
		sid/compute_vad_decision_gmm.sh --nj 10 --use_energy_vad false test/$channel exp/full_ubm_NS_all exp/full_ubm_S_all exp/full_ubm_NT_all exp/test_all_$channel exp/test_all_$channel
	done

	# Not using NT model as we didn't train it for these channels
	channels="G src"
	used_classes="NS S"
	for channel in $channels; do
		sid/compute_vad_decision_gmm.sh --nj 10 --use_energy_vad false test/$channel exp/full_ubm_NS_all exp/full_ubm_S_all exp/test_all_$channel exp/test_all_$channel
	done
fi