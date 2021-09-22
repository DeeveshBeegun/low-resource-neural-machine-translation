OUTDIR=zu_monolingual
datasets_dir=zulu_data/monolingual
tmp=$OUTDIR/tmp

c4_dir=$datasets_dir/c4

mkdir -p $datasets_dir $OUTDIR $tmp

if [ -d $c4_dir ]
then 
    echo "Directory already, skipping download."

else 
    mkdir $c4_dir

    cd $c4_dir 

    GIT_LFS_SKIP_SMUDGE=1 git clone https://huggingface.co/datasets/allenai/c4
    cd c4
    git lfs pull --include "multilingual/c4-zu.*.json.gz"

    cd multiligual


    echo "Gunzipping file..."
    gunzip c4-zu.*.json.gz

    cd ../../../../../

    echo "Converting json to txt file..."
    python3 convert_json_to_txt.py $c4_dir/c4 zu c4-zu.tfrecord-00000-of-00008.json


fi