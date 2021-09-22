#!/bin/bash

src='English'
tgt='IsiXhosa'

file_path='autshumato_eval_set'
dir_path='neural_machine_translation/backtranslation'

cd $file_path
echo "contatenating files"
cat  Autshumato.EvaluationSet.$src.*.txt > combined_autshumato_$src.txt
cat  Autshumato.EvaluationSet.$tgt.*.txt > combined_autshumato_$tgt.txt

cd ../
echo "fairseq interaactive"
fairseq-interactive --input=./autshumato_eval_set/combined_autshumato_English.txt $dir_path/data-bin/en_xh --path neural_machine_translation/backtranslation/checkpoints_en_xh_parallel_plus_bt/checkpoint_best.pt --batch-size 1 --beam 5 --source-lang en --target-lang xh --tokenizer moses --bpe subword_nmt --bpe-codes neural_machine_translation/backtranslation/data-bin/en_xh/code --remove-bpe > backtranslation.txt

echo "grepping"
grep ^H ./backtranslation.txt | cut -f3- > ./backtranslation_mod.txt
fairseq-score --sys ./backtranslation_mod.txt --ref ./autshumato_eval_set/combined_autshumato_IsiXhosa.txt --ignore-case~                                                                                                         