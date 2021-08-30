SCRIPT_DIR=neural_machine_translation/backtranslation/scripts

# Install sacrebleu and sentencepiece
pip install sacrebleu sentencepiece

# Download and preprocess the data
cd neural_machine_translation/multilingual/scripts
bash prepare-en2xh-zu-multilingual.sh
cd ../../..

# Binarize the en-xh dataset
TEXT=SCRIPT_DIR/en-xh.bpe
fairseq-preprocess --source-lang en --target-lang xh \
	--trainpref $TEXT/train.bpe.en-xh \
	--validpref $TEXT/valid0.bpe.en-xh, $TEXT/valid1.bpe.en-xh,$TEXT/valid2.bpe.en-xh,$TEXT/valid3.bpe.en-xh,$TEXT/valid4.bpe.en-xh,$TEXT/valid5.bpe.en-xh \
	--destdir data-bin/en-xh.bpe \
	--workers 10 

# Binarize the en-zu dataset
fairseq-preprocess --source-lang en --target-lang zu \
	--trainpref $TEXT/train.bpe.en-zu \
	--validpref $TEXT/valid0.bpe.en-zu,$TEXT/valid1.bpe.en-zu,$TEXT/valid2.bpe.en-zu,$TEXT/valid3.bpe.en-zu,$TEXT/valid4.bpe.en-zu,$TEXT/valid5.bpe.en-zu \
	--tgtdict data-bin/en-zu.bpe/dict.zu.txt \
	--destdir data-bin/en-zu.bpe \
	--workers 10

# Train a multililngual transformer model
mkdir -p $SCRIPT/checkpoints/multilingual_transformer
CUDA_VISIBLE_DEVICES=0 fairseq-train data-bin/en-zu.bpe/ \
	--max-epoch 4 \
	--ddp-backend=legacy_ddp \
	--task multilingual_translation --lang-pairs en-xh,en-zu \
	--arch multilingual_transformer \
	--share-decoders --share-decoder-input-output-embed \
	--optimizer adam --adam-betas '(0.9, 0.98)' \
	--lr 0.0005 --lr-scheduler inverse_sqrt \
	--warm-updates 4000 --warm-init-lr '1e-07' \
	--label-smoothing 0.1 --criterion label_smoothed_cross_entropy \
	--dropout 0.3 --weight-decay 0.0001 \
	--save-dir $SCRIPT_DIR/checkpoints/multilingual_transformer \
	--max-tokens 100 \
	--update-freq 8



