echo 'Cloning Moses github repository (for tokenization scripts)...'
git clone https://github.com/moses-smt/mosesdecoder.git

echo 'Cloning Subword NMT repository (for BPE pre-processing)...'
git clone https://github.com/rsennrich/subword-nmt.git

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

        # echo "Cleaning data..."
        # python3 prepare_sadilar_bilingual.py $sadilar_dir/sadilar $src $tgt


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

        # echo "Cleaning data..."
        # python3 prepare_opusCorpus_bilingual.py $opusCorpus_dir/jw300 $src $tgt

fi