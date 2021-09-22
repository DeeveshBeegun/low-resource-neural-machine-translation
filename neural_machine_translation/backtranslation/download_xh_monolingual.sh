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

    cd multilingual 

    echo "Gunzipping..."
    gunzip c4-xh.*.json.gz

    cd ../../../../../
    
    echo "Converting json file to text file."
  	python3 convert_json_to_txt.py $c4_dir/c4 xh c4-xh.tfrecord-00000-of-00002.json


fi