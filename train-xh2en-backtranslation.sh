SCRIPT_DIR=neural_machine_translation/backtranslation/scripts

# Download and prepare the data
cd neural_machine_translation/backtranslation/scripts/
#bash prepare-en2xh-baseline.sh
cd ../../..

# # Binarize the data
# TEXT=neural_machine_translation/backtranslation/scripts/baseline-tokenized.en-xh
# fairseq-preprocess \
# 	--joined-dictionary \
# 	--source-lang en --target-lang xh \
# 	--trainpref $TEXT/train --validpref $TEXT/valid --testpref $TEXT/test \
# 	--destdir $SCRIPT_DIR/data-bin/en_xh --thresholdtgt 0 --thresholdsrc 0 \
# 	--workers 20
# # Copy the BPE code into the data-bin directory for future use
# cp neural_machine_translation/backtranslation/scripts/baseline-tokenized.en-xh/code $SCRIPT_DIR/data-bin/en_xh/code

# # Train a reverse model (Xhosa to English) to do the back-translation
CHECKPOINT_DIR=$SCRIPT_DIR/checkpoint_xh_en_parallel
# fairseq-train $SCRIPT_DIR/data-bin/en_xh \
# 	--source-lang xh --target-lang en \
# 	--arch transformer --share-all-embeddings \
# 	--dropout 0.3 --weight-decay 0.0 \
# 	--criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
# 	--optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
# 	--lr 0.001 --lr-scheduler inverse_sqrt --warmup-updates 4000 \
# 	--max-tokens 100 --update-freq 16 \
# 	--max-update 30000 \
# 	--save-dir $CHECKPOINT_DIR

# # Evalate back-translation model to make sure it is well trained
# bash fairseq/backtranslation/sacrebleu.sh \
# 	change-dir-here \
# 	data-bin/en_xh \
# 	data-bin/en_xh/code \
# 	$CHECKPOINT_DIR/checkpoint_best.py

# Prepare monolingual data
cd $SCRIPT_DIR
bash prepare-xh-backtranslation.sh 

cd ../../../
pwd


# Binarize each shard of the monolingual data
TEXT=$SCRIPT_DIR/xh_monolingual
for SHARD in $(seq -f "%02g" 0 1); do \
	fairseq-preprocess \
	--only-source \
	--source-lang xh --target-lang en \
	--joined-dictionary \
	--srcdict $SCRIPT_DIR/data-bin/en_xh/dict.xh.txt \
	--testpref $TEXT/bpe.monolingual.dedup.${SHARD} \
	--destdir $SCRIPT_DIR/data-bin/xh_monolingual/shard${SHARD} \
	--workers 20; \
	cp $SCRIPT_DIR/data-bin/en_xh/dict.en.txt $SCRIPT_DIR/data-bin/xh_monolingual/shard${SHARD}/; \
done

# perform back-translation over the monolingual data


mkdir $SCRIPT_DIR/backtranslation_output
for SHARD in $(seq -f "%02g" 0 1); do \
	fairseq-generate $SCRIPT_DIR/data-bin/xh_monolingual/shard${SHARD} \
	--path $CHECKPOINT_DIR/checkpoint_best.pt \
	--skip-invalid-size-inputs-valid-test \
	--max-tokens 100 \
	--sampling --beam 1 \
	> $SCRIPT_DIR/backtranslation_output/sampling.shard${SHARD}.out; \

done


# use extract_bt_data.py scrit to re-combine the shards, extract the back-translations and apply length ratio filters

python $SCRIPT_DIR/extract_bt_data.py \
	--minlen 1 --maxlen 250 --ratio 1.5 \
	--output $SCRIPT_DIR/backtranslation_output/bt_data --srclang en --tgtlang xh \
	$SCRIPT_DIR/backtranslation_output/sampling.shard*.out

# Binarise the filtered BT data and combine it with the parallel data

TEXT=$SCRIPT_DIR/backtranslation_output
fairseq-preprocess \
	--source-lang en --target-lang xh \
	--joined-dictionary \
	--srcdict $SCRIPT_DIR/data-bin/en_xh/dict.en.txt \
	--trainpref $TEXT/bt_data \
	--destdir $SCRIPT_DIR/data-bin/en_xh_bt \
	--workers 20

# We want to train on the combined data, so we'll symlink the parallel + BT data
# in the wmt18_en_de_para_plus_bt directory. We link the parallel data as "train"
# and the BT data as "train1", so that fairseq will combine them automatically
# and so that we can use the `--upsample-primary` option to upsample the
# parallel data (if desired).
PARA_DATA=$(readlink -f $SCRIPT_DIR/data-bin/en_xh)
BT_DATA=$(readlink -f $SCIRPT_DIR/data-bin/en_xh_bt)
COMB_DATA=$SCRIPT_DIR/data-bin/en_xh_para_plus_bt
mkdir -p $COMB_DATA
for LANG in en xh; do \
    ln -s ${PARA_DATA}/dict.$LANG.txt ${COMB_DATA}/dict.$LANG.txt; \
    for EXT in bin idx; do \
        ln -s ${PARA_DATA}/train.en-xh.$LANG.$EXT ${COMB_DATA}/train.en-xh.$LANG.$EXT; \
        ln -s ${BT_DATA}/train.en-xh.$LANG.$EXT ${COMB_DATA}/train1.en-xh.$LANG.$EXT; \
        ln -s ${PARA_DATA}/valid.en-xh.$LANG.$EXT ${COMB_DATA}/valid.en-xh.$LANG.$EXT; \
        ln -s ${PARA_DATA}/test.en-xh.$LANG.$EXT ${COMB_DATA}/test.en-xh.$LANG.$EXT; \
    done; \
done

# Train a model over the parallel + BT data 

CHECKPOINT_DIR=$SCRIPT_DIR/checkpoints_en_xh_parallel_plus_bt
fairseq-train $SCRIPT_DIR/data-bin/en_xh_para_plus_bt \
	--upsample-primary 16 \
	--source-lang en --target-lang xh \
	--arch transformer --share-all-embeddings \
	--dropout 0.3 --weight-decay 0.0 \
	--criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
	--optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
	--lr 0.007 --lr-scheduler inverse_sqrt --warmup-updates 4000 \
	--max-tokens 100 --update-freq 16 \
	--max-update 10000 \
	--max-epoch 4 \
	--save-dir $CHECKPOINT_DIR

# # average the last 10 checkpoints
# python scripts/average_checkpoints.py \
# 	--inputs $CHECKPOINT_DIR \
# 	--num-epoch-checkpoints 10 \
# 	--output $CHECKPOINT_DIR/checkpoint.avg10.pt

# # detokenized sacrebleu
# bash fairseq/backtranslation/sacrebleu.sh \
# 	change_dir \
# 	en-xh \
# 	data-bin/en_xh \
# 	data-bin/en_xh/code \
# 	$CHECKPOINT_DIR/checkpoint.avg10.pt


	
