#!/usr/bin/env bash
#
# Adapted from https://github.com/facebookresearch/MIXER/blob/master/prepareData.sh

SCRIPTS=mosesdecoder/scripts
TOKENIZER=$SCRIPTS/tokenizer/tokenizer.perl
BPEROOT=subword-nmt/subword_nmt

BPE_CODE=data-bin/en_xh/code
SUBSAMPLE_SIZE=2500
LANG=xh

OUTDIR=xh_monolingual
datasets=xhosa_data/monolingual
tmp=$OUTDIR/tmp

mkdir -p $OUTDIR $tmp

# if [ -d $datasets ]
# then 
# 	echo "Directory already exist."

# else 
# 	cd $datasets

# 	url_xho_sadilar='https://repo.sadilar.org/bitstream/handle/20.500.12185/524/Corpus.SADiLaR.English-isiXhosaDrop-Monolingual.1.0.0.CAM.2019-11-15.xh.txt?sequence=1&isAllowed=y'

# 	echo "Downloading Xhosa monolingual corpus from the sadilar website..."
# 	wget $url_xho_sadilar

# 	echo "Cleaning data..."
# 	python3 scripts/prepare_sadilar_monolingual.py $sadilar_dir/sadilar.xh $tgt

# 	cd ..

# fi

if [ -f $tmp/monolingual.${SUBSAMPLE_SIZE}.${LANG} ]; then
	echo "found monolingual sample, skipping shuffle/sample/tokenize"
else
	cat $datasets/clinical.xh \
	| shuf -n $SUBSAMPLE_SIZE \
	| perl $TOKENIZER -threads 8 -a -l $LANG \
	> $tmp/monolingual.${SUBSAMPLE_SIZE}.${LANG}

fi

if [ -f $tmp/bpe.monolingual.${SUBSAMPLE_SIZE}.${LANG} ]; then 
	echo "found BPE monolingual sample, skipping BPE step"
else
	 python $BPEROOT/apply_bpe.py -c $BPE_CODE \
        < $tmp/monolingual.${SUBSAMPLE_SIZE}.${LANG} \
        > $tmp/bpe.monolingual.${SUBSAMPLE_SIZE}.${LANG}

fi

if [ -f $tmp/bpe.monolingual.dedup.${SUBSAMPLE_SIZE}.${LANG} ]; then
    echo "found deduplicated monolingual sample, skipping deduplication step"
else
    python deduplicate_lines.py $tmp/bpe.monolingual.${SUBSAMPLE_SIZE}.${LANG} \
    > $tmp/bpe.monolingual.dedup.${SUBSAMPLE_SIZE}.${LANG}
fi

if [ -f $OUTDIR/bpe.monolingual.dedup.00.xh ]; then
    echo "found sharded data, skipping sharding step"
else
    split --lines 100 --numeric-suffixes \
        --additional-suffix .${LANG} \
        $tmp/bpe.monolingual.dedup.${SUBSAMPLE_SIZE}.${LANG} \
        $OUTDIR/bpe.monolingual.dedup.
fi
