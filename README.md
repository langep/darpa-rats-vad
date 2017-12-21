# GMM-based Speech Activity Detection

The code can also be found in the github repository at [https://github.com/langep/darpa-rats-vad](https://github.com/langep/darpa-rats-vad).

## The original data
This experiment is based of DARPA RATS corpus. Access has been granted by my employer but I canont share the data. I have shared the extracted features and indicated below which scripts can be run with the submission.

## Directory structre
- conf: feature extraction related configuration
- ground_truth: the ground truth labels for the test set utterances
- local: copy from wsj steps and other egs
- scores: the results from decoding
- sid: copy from egs/sre08/v1/
- steps: copy from egs/sre08/v1/
- utils: egs/sre08/v1/


## Contribution
- scripts in scripts/ have been written by me
- sid/compute_vad_decisions_gmm.sh has been modified to write results in text form by adding 't,' in front of the wspecifier of the results


## Running the experiment

Setup kaldi location, data location, create symlinks, etc.
!NOTE: You can enter any directory for <path-to-rats-data> if you don't have the darpa rats data.
	   Be aware to not run any scripts that are marked as requiring the original data.
```
bash scripts/initial_setup.sh <path-to-kaldi> <path-to-rats-data>
```

Segment training audio and prepare for experiment
!Requires original data. Output provided.
```
bash scripts/prepare_train.sh
```

Create features and vad decisions for training
```
bash scripts/make_train_set_features.sh
bash scripts/make_train_set_vad_decisions.sh
```

Train channel specific GMM models
```
bash scripts/train_diag_ubms.sh
bash scripts/train_full_ubms.sh
```

Train a single model using all channels
```
bash train_combined_model.sh 1
# Manually delete C_S.6.093 from S/all/wav.scp and S/all/utt2spk because there are no feats generated for it.
bash scripts/train_combined_model.sh 2
```

Prepare test data, features, etc.
!Requires original data. Output provided
```
bash scripts/prepare_test.sh
```

Run the decoding
```
bash scripts/decode.sh
```

Produce the scores
```
bash scripts/create_scores.sh
```

The scores can now be found in scores/
