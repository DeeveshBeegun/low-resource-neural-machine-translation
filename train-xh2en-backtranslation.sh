eval "$(conda shell.bash hook)"
conda activate /home/dbeegun/fairSeq

BACKTRANS_DIR=neural_machine_translation/backtranslation

# Download and prepare the data
cd $BACKTRANS_DIR
#bash prepare-en2xh-baseline.sh

cd ../../

# Binarize the data
TEXT=$BACKTRANS_DIR/baseline-tokenized.en-xh/

fairseq-preprocess \
        --joined-dictionary \
        --source-lang en --target-lang xh \
        --trainpref $TEXT/train --validpref $TEXT/valid --testpref $TEXT/test \
        --destdir $BACKTRANS_DIR/data-bin/en_xh --thresholdtgt 0 --thresholdsrc 0 \
        --workers 20
# Copy the BPE code into the data-bin directory for future use
cp $BACKTRANS_DIR/baseline-tokenized.en-xh/code $BACKTRANS_DIR/data-bin/en_xh/code


# Train a reverse model (Xhosa to English) to do the back-translation
CHECKPOINT_DIR=$BACKTRANS_DIR/checkpoint_xh_en_parallel
CUDA_VISIBLE_DEVICES=1 fairseq-train $BACKTRANS_DIR/data-bin/en_xh \
        --source-lang xh --target-lang en \
         --arch transformer --share-decoder-input-output-embed \
        --dropout 0.1 --weight-decay 0.0 \
        --criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
        --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
        --lr 0.001 --lr-scheduler inverse_sqrt --warmup-updates 4000 \
        --max-tokens 4000 --update-freq 16 \
        --max-epoch 15 \
        --patience 5 \
        --fp16 \
    --eval-bleu \
    --eval-bleu-args '{"beam": 5, "max_len_a": 1.2, "max_len_b": 10}' \
    --eval-bleu-detok moses \
    --eval-bleu-remove-bpe \
    --eval-bleu-print-samples \
    --best-checkpoint-metric bleu --maximize-best-checkpoint-metric \
        --save-dir $CHECKPOINT_DIR

# Compute bleu score of the reversed model

# Prepare monolingual data
cd $BACKTRANS_DIR
bash prepare-xh-backtranslation.sh

cd ../../


# Binarize each shard of the monolingual data
TEXT=$BACKTRANS_DIR/xh_monolingual
for SHARD in $(seq -f "%02g" 0 24); do \
        fairseq-preprocess \
        --only-source \
        --source-lang xh --target-lang en \
        --joined-dictionary \
        --srcdict $BACKTRANS_DIR/data-bin/en_xh/dict.xh.txt \
        --testpref $TEXT/bpe.monolingual.dedup.${SHARD} \
        --destdir $BACKTRANS_DIR/data-bin/xh_monolingual/shard${SHARD} \
        --workers 20; \
        cp $BACKTRANS_DIR/data-bin/en_xh/dict.en.txt $BACKTRANS_DIR/data-bin/xh_monolingual/shard${SHARD}/; \
done

# perform back-translation over the monolingual data
mkdir $BACKTRANS_DIR/backtranslation_output
for SHARD in $(seq -f "%02g" 0 24); do \
        fairseq-generate $BACKTRANS_DIR/data-bin/xh_monolingual/shard${SHARD} \
        --path $CHECKPOINT_DIR/checkpoint_best.pt \
        --skip-invalid-size-inputs-valid-test \
        --max-tokens 4000 \
        --sampling --beam 1 \
        > $BACKTRANS_DIR/backtranslation_output/sampling.shard${SHARD}.out; \

done


# use extract_bt_data.py scrit to re-combine the shards, extract the back-translations and apply length ratio filters
python $BACKTRANS_DIR/extract_bt_data.py \
        --minlen 5 --maxlen 200 --ratio 9 \
        --output $BACKTRANS_DIR/backtranslation_output/bt_data --srclang en --tgtlang xh \
        $BACKTRANS_DIR/backtranslation_output/sampling.shard*.out

# Binarise the filtered BT data and combine it with the parallel data
TEXT=$BACKTRANS_DIR/backtranslation_output
fairseq-preprocess \
        --source-lang en --target-lang xh \
        --joined-dictionary \
        --srcdict $BACKTRANS_DIR/data-bin/en_xh/dict.en.txt \
        --trainpref $TEXT/bt_data \
        --destdir $BACKTRANS_DIR/data-bin/en_xh_bt \
        --workers 20

# We want to train on the combined data, so we'll symlink the parallel + BT data
# in the wmt18_en_de_para_plus_bt directory. We link the parallel data as "train"
# and the BT data as "train1", so that fairseq will combine them automatically
# and so that we can use the `--upsample-primary` option to upsample the
# parallel data (if desired).
PARA_DATA=$(readlink -f $BACKTRANS_DIR/data-bin/en_xh)
BT_DATA=$(readlink -f $BACKTRANS_DIR/data-bin/en_xh_bt)
COMB_DATA=$BACKTRANS_DIR/data-bin/en_xh_para_plus_bt
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
CHECKPOINT_DIR=$BACKTRANS_DIR/checkpoints_en_xh_parallel_plus_bt
CUDA_VISIBLE_DEVICES=1 fairseq-train --fp16 \
         $BACKTRANS_DIR/data-bin/en_xh_para_plus_bt \
        --source-lang en --target-lang xh \
        --upsample-primary 1 \
        --arch transformer --share-decoder-input-output-embed \
        --dropout 0.1 --weight-decay 0.0 \
        --criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
        --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
        --lr 5e-4 --lr-scheduler inverse_sqrt --warmup-updates 4000 \
        --max-tokens 4000 --update-freq 16 \
        --max-epoch 15 \
        --patience 5 \
        --eval-bleu \
    --eval-bleu-args '{"beam": 5, "max_len_a": 1.2, "max_len_b": 10}' \
    --eval-bleu-detok moses \
    --eval-bleu-remove-bpe \
    --eval-bleu-print-samples \
    --best-checkpoint-metric bleu --maximize-best-checkpoint-metric \
        --save-dir $CHECKPOINT_DIR