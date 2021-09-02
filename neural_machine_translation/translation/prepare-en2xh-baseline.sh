#!/usr/bin/env bash
#
# Adapted from https://github.com/facebookresearch/MIXER/blob/master/prepareData.sh

# echo 'Cloning Moses github repository (for tokenization scripts)...'
# git clone https://github.com/moses-smt/mosesdecoder.git

# echo 'Cloning Subword NMT repository (for BPE pre-processing)...'
# git clone https://github.com/rsennrich/subword-nmt.git

SCRIPTS=mosesdecoder/scripts
TOKENIZER=$SCRIPTS/tokenizer/tokenizer.perl
CLEAN=$SCRIPTS/training/clean-corpus-n.perl
LC=$SCRIPTS/tokenizer/lowercase.perl
BPEROOT=subword-nmt/subword_nmt
BPE_TOKENS=10000

src=en
tgt=xh
lang=en-xh
prep=baseline-tokenized.en-xh
tmp=$prep/tmp
datasets_dir=xhosa_data/parallel # directory containing all the datasets 

sadilar_dir=$datasets_dir/sadilar # contains sadilar datasets (xhosa_data -> parallel -> sadilar)
opusCorpus_dir=$datasets_dir/opus_corpus # contains jw300 datasets
memat_dir=$datasets_dir/memat # contains memat datasets

dataset_num=3

# mkdir -p $datasets_dir $tmp $prep

# if [ -d $sadilar_dir ]
# then 
# 	echo "Directory already exist."

# else 
# 	mkdir -p $sadilar_dir 

# 	url_eng_sadilar='https://repo.sadilar.org/bitstream/handle/20.500.12185/525/Corpus.SADiLaR.English-isiXhosaDrop-Bilingual.1.0.0.CAM.2019-11-15.en.txt?sequence=1&isAllowed=y'
# 	url_xho_sadilar='https://repo.sadilar.org/bitstream/handle/20.500.12185/525/Corpus.SADiLaR.English-isiXhosaDrop-Bilingual.1.0.0.CAM.2019-11-15.xh.txt?sequence=2&isAllowed=y'

# 	echo "Downloading English corpus from the sadilar website..."
# 	wget $url_eng_sadilar --output-document $sadilar_dir/sadilar.en

# 	echo "Downloading Xhosa corpus from the sadilar website..."
# 	wget $url_xho_sadilar --output-document $sadilar_dir/sadilar.xh

echo "Cleaning data..."
python3 prepare_sadilar_bilingual.py $sadilar_dir/sadilar $src $tgt

# fi


# if [ -d $opusCorpus_dir ]
# then 
# 	echo "Directory already exist."

# else
# 	mkdir -p $opusCorpus_dir

# 	cd $opusCorpus_dir

# 	echo "Downloading jw300 datasets from Opus Corpus..."
# 	pip install opustools
# 	opus_read -d JW300 -s xh -t en -wm moses -w jw300.xh jw300.en

# 	cd ../../../

echo "Cleaning data..."
python3 prepare_opusCorpus_bilingual.py $opusCorpus_dir/jw300 $src $tgt

# fi


# if [ -d $memat_dir ]
# then 
# 	echo "Directory already exist."

# else
# 	mkdir -p $memat_dir

# 	cd $memat_dir

# 	echo "Cloning data from memat git repository..."
# 	git clone https://github.com/mkeet/MeMat.git

# 	cd ../../../

echo "Cleaning data..."
python3 prepare_memat_bilingual.py $memat_dir $src $tgt

# fi

echo "Splitting dataset into training and testing sets..."

declare -a datasets

datasets=($sadilar_dir $opusCorpus_dir $memat_dir)

python3 train_test_split.py $datasets_dir $dataset_num ${datasets[@]} $src $tgt

echo "pre-processing train data..."

for l in $src $tgt; do
	f=train.tags.$lang.$l
	tok=train.tags.$lang.tok.$l

	cat $datasets_dir/$f | perl $TOKENIZER -threads 8 -l $l > $tmp/$tok
	echo ""
done

perl $CLEAN -ratio 9 $tmp/train.tags.$lang.tok $src $tgt $tmp/train.tags.$lang.clean 5 200
for l in $src $tgt; do
    perl $LC < $tmp/train.tags.$lang.clean.$l > $tmp/train.tags.$lang.$l
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
	awk '{if (NR%100 == 0)  print $0; }' $tmp/train.tags.en-xh.$l > $tmp/valid.$l
    awk '{if (NR%100 != 0)  print $0; }' $tmp/train.tags.en-xh.$l > $tmp/train.$l

done

TRAIN=$tmp/train.xh-en
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











