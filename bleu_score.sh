#!/bin/bash

src='English'
tgt='IsiXhosa'

file_path='autshumato_eval_set'
dir_path='neural_machine_translation/translation'

cd $file_path
echo "contatenating files"
cat  Autshumato.EvaluationSet.$src.*.txt > combined_autshumato_$src.txt
cat  Autshumato.EvaluationSet.$tgt.*.txt > combined_autshumato_$tgt.txt

cd ../
echo "fairseq interaactive"
fairseq-interactive --input=./autshumato_eval_set/combined_autshumato_English.txt data-bin-en2xh/baseline-tokenized.en-xh --path neural_machine_translation/translation/checkpoint_en2xh_4/checkpoint_best.pt --batch-size 1 --beam 5 --source-lang en --target-lang xh --tokenizer moses --bpe subword_nmt --bpe-codes neural_machine_translation/translation/baseline-tokenized.en-xh/code --remove-bpe > translation.txt

echo "grepping"
grep ^H ./translation.txt | cut -f3- > ./translation_mod.txt
fairseq-score --sys ./translation_mod.txt --ref ./autshumato_eval_set/combined_autshumato_IsiXhosa.txt --ignore-case
                                                                                                                      ~                                                                                                                     