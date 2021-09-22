# Script for training Enlgish to IsiXhosa to IsiZulu multilingual model

eval "$(conda shell.bash hook)"
conda activate /home/dbeegun/fairSeq

pip install sacremoses
pip install sacrebleu==1.5.1


# Download and preprocess the data
cd neural_machine_translation/multilingual/
bash prepare-en2zu-baseline.sh
bash prepare-en2xh-baseline.sh
cd ../..

# Binarize the en-xh dataset
TEXT=neural_machine_translation/multilingual/tokenized.xhzu-en

fairseq-preprocess --source-lang en --target-lang xh \
        --trainpref $TEXT/train \
        --validpref $TEXT/valid --testpref $TEXT/test \
        --destdir data-bin/tokenized.xhzu.en \
        --workers 20

TEXTZU=neural_machine_translation/multilingual/tokenized.xhzu-en2
# Binarize the en-zu dataset
fairseq-preprocess --source-lang en --target-lang zu \
        --trainpref $TEXTZU/train \
        --validpref $TEXTZU/valid --testpref $TEXTZU/test \
        --srcdict data-bin/tokenized.xhzu.en/dict.en.txt \
        --destdir data-bin/tokenized.xhzu.en \
        --workers 20

# Train a multililngual transformer model
mkdir -p neural_machine_translation/multilingual/checkpoints/multilingual_transformer
CUDA_VISIBLE_DEVICES=1 fairseq-train data-bin/tokenized.xhzu.en/ \
        --max-epoch 15 \
        --fp16 \
        --update-freq 16 \
        --ddp-backend=legacy_ddp \
        --task multilingual_translation --lang-pairs en-xh,en-zu \
        --arch multilingual_transformer --share-decoder-input-output-embed \
        --optimizer adam --adam-betas '(0.9, 0.98)' \
        --lr 0.0005 --lr-scheduler inverse_sqrt \
        --warmup-updates 4000 --warmup-init-lr '1e-07' \
        --label-smoothing 0.1 --criterion label_smoothed_cross_entropy \
        --dropout 0.2 --weight-decay 0.0 \
        --patience 5 \
        --save-dir neural_machine_translation/multilingual/checkpoints/multilingual_transformer \
        --max-tokens 4000  \
        --update-freq 8