fairseq-interactive --input=source_english.txt data-bin-en2xh/baseline-tokenized.en-xh --path checkpoints/checkpoint_best.pt --batch-size 1 --beam 5 > target.txt

grep ^H ./target.txt | cut -f3- > ./target_mod.txt
fairseq-score --sys ./target_mod.txt --ref ./target_xhosa.txt
