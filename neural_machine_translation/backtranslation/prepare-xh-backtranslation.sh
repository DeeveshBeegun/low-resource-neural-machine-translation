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
datasets_dir=xhosa_data/monolingual
tmp=$OUTDIR/tmp

sadilar_dir=$datasets_dir/sadilar
c4_dir=$datasets_dir/c4

mkdir -p $datasets_dir $OUTDIR $tmp

if [ -d $sadilar_dir ]
then 
	echo "Directory already exist."

else 
	mkdir $sadilar_dir

	url_xho_sadilar='https://repo.sadilar.org/bitstream/handle/20.500.12185/524/Corpus.SADiLaR.English-isiXhosaDrop-Monolingual.1.0.0.CAM.2019-11-15.xh.txt?sequence=1&isAllowed=y'

	echo "Downloading Xhosa monolingual corpus from the sadilar website..."
	wget $url_xho_sadilar --output-document $sadilar_dir/sadilar.xh

	# echo "Cleaning data..."
	# python3 scripts/prepare_sadilar_monolingual.py $sadilar_dir/sadilar.xh

	cd ..

fi

if [ -d $c4_dir ]
then 
    echo "Directory already, skipping download."

else 
    mkdir $c4_dir

    cd $c4_dir 

    GIT_LFS_SKIP_SMUDGE=1 git clone https://huggingface.co/datasets/allenai/c4
    cd c4
    git lfs pull --include "multilingual/c4-xh.*.json.gz"

    cd multiligual 

    gunzip c4-xh.*.json.gz

    python3 prepare_c4_monolingual.py 1 *-xh.*-00000-*.json

    cd ../../

fi


if [ -f $tmp/monolingual.${SUBSAMPLE_SIZE}.${LANG} ]; then
	echo "found monolingual sample, skipping shuffle/sample/tokenize"
else
	cat $sadilar_dir/saidlar.xh $c4_dir/multiligual/c4.xh \
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
