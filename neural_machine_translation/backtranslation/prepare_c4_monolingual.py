import pandas as pd 
import system

number_of_corpora = sys.argv[1]

for i in range(2, number_of_corpora+1):
	data = pd.read_json('./' + sys.argv[i], lines=True)
	data.to_csv('./c4' + sys.argv[i] + '.' + lang, index=False, mode = 'a')

 c4-zu.tfrecord-00000-of-00008.json

 c4-zu.tfrecord-00001-of-00008.json