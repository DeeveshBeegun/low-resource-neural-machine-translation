#!/bin/bash

src='English'
tgt='IsiXhosa'

file_path='autshumato_eval_set/'
dir_path='neural_machine_translation/translation/'

cd $file_path

cat  Autshumato.EvaluationSet.$src.*.txt >> combined_autshumato_$src.txt
cat  Autshumato.EvaluationSet.$tgt.*.txt >> combined_autshumato_$tgt.txt

cd ../

fairseq-interactive --input=./combined_autshumato_$src.txt $dir_path/data-bin-en2xh/baseline-tokenized.en-xh --path checkpoints/checkpoint_best.pt --batch-size 1 --beam 5 > translation.txt

grep ^H ./translation.txt | cut -f3- > ./translation_mod.txt
fairseq-score --sys ./translation_mod.txt --ref ./combined_autshumato_$tgt.txt
