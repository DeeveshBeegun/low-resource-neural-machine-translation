#!/bin/bash

src='English'
tgt='IsiZulu'

file_path='autshumato_eval_set'
dir_path='neural_machine_translation/multilingual'

cd $file_path
echo "contatenating files"
cat  Autshumato.EvaluationSet.$src.*.txt > combined_autshumato_$src.txt
cat  Autshumato.EvaluationSet.$tgt.*.txt > combined_autshumato_$tgt.txt

cd ../
echo "fairseq interaactive"
fairseq-interactive --input=./autshumato_eval_set/combined_autshumato_English.txt data-bin/tokenized.xhzu.en/ --task multilingual_translation --lang-pairs en-xh,en-zu --path neural_machine_translation/multilingual/checkpoints/multilingual_transformer/checkpoint_best.pt --batch-size 1 --beam 5 --source-lang en --target-lang zu --tokenizer moses --bpe subword_nmt --bpe-codes neural_machine_translation/multilingual/tokenized.xhzu-en2/code --remove-bpe > translation_multi_zu.txt

echo "grepping"
grep ^H ./translation_multi_zu.txt | cut -f3- > ./translation_mod_multi_zu.txt
fairseq-score --sys ./translation_mod_multi_zu.txt --ref ./autshumato_eval_set/combined_autshumato_IsiZulu.txt --ignore-case