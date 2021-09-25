# Transformer Neural Machine Translation for Nguni langauges

Neural Machine Translation (NMT) has shown significant improvements over traditional phrase-based machine translation over recent years. Nonetheless, NMT models have a steep learning curve with respect to the amount of data thus underperform when the amount of training data is limited, as in the case of low resource languages. South African languages being under-resourced have achieved low performance in the machine translation paradigm. To address this issue, we compare different data augmentation techniques on two Nguni langauges, namely, IsiXhosa and IsiZulu, with English to IsiXhosa and English to IsiZulu baseline models. The first data augmentation technique makes use of target-side monolingual data to augment the amount of parallel data via backtranslation (convert target-side language into source-side language) and the second technique involves training a multilingual model on a joint set of bilingual corpora containing both the IsiXhosa and IsiZulu language.


1) download monolingual and bilingual data by running download scripts found at the following paths:



run download_zu_bilingual.sh to download bilingual IsiZulu data
run download_zu_monolingual.sh to download monolingual IsiZulu data
run download_xh_bilingual.sh to downlaod bilingual IsiXhosa data
run download_xh_monolingaul to download monolingual IsiXhosa data

run train-en2xh-baseline.sh to prepare data and train English to IsiXhosa baseline model
run train-en2zu-baseline.sh to prepare data and train English to IsiZulu baseline model
run train-en2xhzu-multilingual.sh to prepare data and train English to IsiXhosa and IsiZulu multilingual model
run train-xh2en-backtranslatino to preapre data and train IsiXhosa to english on augmented parallel data
