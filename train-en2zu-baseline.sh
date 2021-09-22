# Script for training baseline English to IsiZulu model

eval "$(conda shell.bash hook)"
conda activate /home/dbeegun/fairSeq

pip install sacremoses
pip install sacrebleu==1.5.1

TRANS=neural_machine_translation/translation

# Download and prepare the data
cd neural_machine_translation/translation/
bash prepare-en2zu-baseline.sh
cd ../..

# Preprocess/binarize the data
TEXT=$TRANS/baseline-tokenized.en-zu
fairseq-preprocess --source-lang en --target-lang zu \
        --trainpref $TEXT/train --validpref $TEXT/valid --testpref $TEXT/test \
        --destdir data-bin-en2zu/baseline-tokenized.en-zu \
        --workers 20

# Train translation model over data
CHECKPOINT_DIR=$TRANS/checkpoint_en2zu_7
CUDA_VISIBLE_DEVICES=1 fairseq-train \
        data-bin-en2zu/baseline-tokenized.en-zu \
        --arch transformer --share-decoder-input-output-embed \
        --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
        --lr 5e-4 --lr-scheduler inverse_sqrt --warmup-updates 4000 \
                --optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
        --lr 5e-4 --lr-scheduler inverse_sqrt --warmup-updates 4000 \
        --dropout 0 --weight-decay 0 \
        --criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
        --max-tokens 4096 \
        --fp16 \
        --max-epoch 15 \
        --patience 5 \
        --eval-bleu \
        --eval-bleu-args '{"beam": 5, "max_len_a": 1.2, "max_len_b": 10}'\
        --eval-bleu-detok moses \
        --eval-bleu-remove-bpe \
        --eval-bleu-print-samples \
        --best-checkpoint-metric bleu --maximize-best-checkpoint-metric \
        --save-dir $CHECKPOINT_DIR