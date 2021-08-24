# This script is for training the baseline NMT model for the translation of English to isiXhosa

# Download and prepare the data
cd examples/translation/
bash prepare-en2xh-baseline.sh
cd ../..

# Preprocess/binarize the data
TEXT=examples/translation/baseline-tokenized.en-xh
fairseq-preprocess --source-lang en --target-lang xh \
	--trainpref $TEXT/train --validpref $TEXT/valid --testpref $TEXT/test \
	--destdir data-bin/baseline-tokenized.en-xh \
	--workers 20

# Train translation model over data
CUDA_VISIBLE_DEVICES=0 fairseq-train \
	data-bin/baseline-tokenized.en-xh \
	--arch transformer --share-decoder-input-output-embed \
	--optimizer adam --adam-betas '(0.9, 0.98)' --clip-norm 0.0 \
	--lr 5e-4 --lr-scheduler inverse_sqrt --warmup-updates 4000 \
	--dropout 0.3 --weight-decay 0.0001 \
	--criterion label_smoothed_cross_entropy --label-smoothing 0.1 \
	--max-tokens 4096 \
	--eval-bleu \
	--eval-bleu-args '{"beam": 5, "max_len_a": 1.2, "max_len_b": 10}'\
	--eval-bleu-detok moses \
	--eval-bleu-remove-bpe \
	--eval-bleu-print-samples \
	--best-checkpoint-metric bleu --maximize-best-checkpoint-metric

# Evaluate trained model
fairseq-generate data-bin/baseline-tokenized.en-xh \
	--path checkpoints/checkpoint_best.pt \
	--batch-size 128 --beam 5 --remove-bpe

