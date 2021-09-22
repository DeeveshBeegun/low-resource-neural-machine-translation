#!/usr/bin/env bash
#
# Adapted from https://github.com/facebookresearch/MIXER/blob/master/prepareData.sh

SCRIPTS=mosesdecoder/scripts
TOKENIZER=$SCRIPTS/tokenizer/tokenizer.perl
BPEROOT=subword-nmt/subword_nmt

BPE_CODE=data-bin/en_zu/code
SUBSAMPLE_SIZE=250000
LANG=zu

OUTDIR=zu_monolingual
datasets_dir=zulu_data/monolingual
tmp=$OUTDIR/tmp

c4_dir=$datasets_dir/c4

mkdir -p $datasets_dir $OUTDIR $tmp


# if [ -d $c4_dir ]
# then
#     echo "Directory already, skipping download."

# else
#     mkdir $c4_dir

#     cd $c4_dir
#     GIT_LFS_SKIP_SMUDGE=1 git clone https://huggingface.co/datasets/allenai/c4
#     cd c4
#     git lfs pull --include "multilingual/c4-zu.*.json.gz"

#     cd multiligual

#     gunzip c4-zu.*.json.gz

#     python3 prepare_c4_monolingual.py *-zu.*-00000-*.json *-zu.*-00001-*json

#     cd ../../

# fi

python3 prepare_c4_monolingual.py $c4_dir/multilingual/c4/c4_dataset.zu



if [ -f $tmp/monolingual.${SUBSAMPLE_SIZE}.${LANG} ]; then
        echo "found monolingual sample, skipping shuffle/sample/tokenize"
else
        cat $c4_dir/multilingual/c4/c4_dataset.zu.cleaned \
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

if [ -f $OUTDIR/bpe.monolingual.dedup.00.zu ]; then
    echo "found sharded data, skipping sharding step"
else
    split --lines 10000 --numeric-suffixes \
        --additional-suffix .${LANG} \
        $tmp/bpe.monolingual.dedup.${SUBSAMPLE_SIZE}.${LANG} \
        $OUTDIR/bpe.monolingual.dedup.
fi
