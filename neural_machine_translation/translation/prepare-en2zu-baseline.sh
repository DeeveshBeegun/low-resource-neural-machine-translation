#!/usr/bin/env bash
#
# Adapted from https://github.com/facebookresearch/MIXER/blob/master/prepareData.sh

echo 'Cloning Moses github repository (for tokenization scripts)...'
git clone https://github.com/moses-smt/mosesdecoder.git

echo 'Cloning Subword NMT repository (for BPE pre-processing)...'
git clone https://github.com/rsennrich/subword-nmt.git

SCRIPTS=mosesdecoder/scripts
TOKENIZER=$SCRIPTS/tokenizer/tokenizer.perl
CLEAN=$SCRIPTS/training/clean-corpus-n.perl
LC=$SCRIPTS/tokenizer/lowercase.perl
BPEROOT=subword-nmt/subword_nmt
BPE_TOKENS=10000

src=en
tgt=zu
lang=en-zu
prep=baseline-tokenized.en-zu
tmp=$prep/tmp
datasets_dir=zulu_data/parallel # directory containing all the datasets 

sadilar_dir=$datasets_dir/sadilar # contains sadilar datasets (zulu -> parallel -> sadilar)
opusCorpus_dir=$datasets_dir/opus_corpus # contains jw300 datasets

dataset_num=2

mkdir -p $datasets_dir $tmp $prep

if [ -d $sadilar_dir ]
then 
	echo "Directory already exist, skipping downloading."

else 
	mkdir -p $sadilar_dir 

	url_eng_zu_sadilar="https://repo.sadilar.org/bitstream/handle/20.500.12185/399/en-zu.release.zip?sequence=3&isAllowed=y"

	echo "Downloading English and Zulu corpora from the sadilar website..."
	wget $url_eng_zu_sadilar --output-document $sadilar_dir/sadilar.zip

	cd $sadilar_dir

	unzip sadilar.zip

	mv *.eng.*.txt sadilar.en
	mv *.zul.*.txt sadilar.zu

	cd ../../../

	echo "Cleaning data..."
	python3 prepare_sadilar_bilingual.py $sadilar_dir/sadilar $src $tgt
	

fi


if [ -d $opusCorpus_dir ]
then 
	echo "Directory already exist, skipping downloading."

else
	mkdir -p $opusCorpus_dir

	cd $opusCorpus_dir

	echo "Downloading jw300 datasets from Opus Corpus..."
	pip install opustools
	opus_read -d JW300 -s zu -t en -wm moses -w jw300.zu jw300.en

	cd ../../../

	echo "Cleaning data..."
	python3 prepare_opusCorpus_bilingual.py $opusCorpus_dir/jw300 $src $tgt

fi

python3 prepare_opusCorpus_bilingual.py $opusCorpus_dir/jw300 $src $tgt


echo "Splitting dataset into training and testing sets..."

declare -a datasets

datasets=($sadilar_dir $opusCorpus_dir)

python3 train_test_split.py $datasets_dir $dataset_num ${datasets[@]} $src $tgt

echo "pre-processing train data..."

for l in $src $tgt; do
	f=train.tags.$lang.$l
	tok=train.tags.$lang.tok.$l

	cat $datasets_dir/$f | perl $TOKENIZER -threads 8 -l $l > $tmp/$tok
	echo ""
done

perl $CLEAN $tmp/train.tags.$lang.tok $src $tgt $tmp/train.tags.$lang.clean 1 175
for l in $src $tgt; do
    perl $LC < $tmp/train.tags.$lang.tok.$l > $tmp/train.tags.$lang.$l
done

echo "pre-processing valid/test data..."

for l in $src $tgt; do
	f=$tmp/test.$l

	cat $datasets_dir/test.$l | perl $TOKENIZER -threads 8 -l $l | \
	perl $LC > $f
	echo ""
done 

echo "creating train, valid, test..."
for l in $src $tgt; do
	awk '{if (NR%100 == 0)  print $0; }' $tmp/train.tags.en-zu.$l > $tmp/valid.$l
    awk '{if (NR%100 != 0)  print $0; }' $tmp/train.tags.en-zu.$l > $tmp/train.$l

done

TRAIN=$tmp/train.zu-en
BPE_CODE=$prep/code
rm -f $TRAIN
for l in $src $tgt; do
    cat $tmp/train.$l >> $TRAIN
done

echo "learn_bpe.py on ${TRAIN}..."
python $BPEROOT/learn_bpe.py -s $BPE_TOKENS < $TRAIN > $BPE_CODE

for L in $src $tgt; do
    for f in train.$L valid.$L test.$L; do
        echo "apply_bpe.py to ${f}..."
        python $BPEROOT/apply_bpe.py -c $BPE_CODE < $tmp/$f > $prep/$f
    done
done
