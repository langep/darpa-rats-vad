# GMM-based Speech Activity Detection

The code can also be found in the github repository at [https://github.com/langep/darpa-rats-vad](https://github.com/langep/darpa-rats-vad).

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
