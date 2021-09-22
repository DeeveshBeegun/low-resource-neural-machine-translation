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
fairseq-interactive --input=./autshumato_eval_set/combined_autshumato_English.txt data-bin/tokenized.xhzu.en/ --task multilingual_translation --lang-pairs en-xh,en-zu --path neural_machine_translation/multilingual/checkpoints/multilingual_transformer/checkpoint_best.pt --batch-size 1 --beam 5 --source-lang en --target-lang xh --tokenizer moses --bpe subword_nmt --bpe-codes neural_machine_translation/multilingual/tokenized.xhzu-en/code --remove-bpe > translation_multi.txt

echo "grepping"
grep ^H ./translation_multi.txt | cut -f3- > ./translation_mod_multi.txt
fairseq-score --sys ./translation_mod_multi.txt --ref ./autshumato_eval_set/combined_autshumato_IsiXhosa.txt --ignore-case
                                                                                          