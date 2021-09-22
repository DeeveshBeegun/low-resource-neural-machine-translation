import pandas as pd 
import sys

dir_path = sys.argv[1]
lang = sys.argv[2]

file_path = './' + dir_path + '/multilingual/' + sys.argv[3]

file_path_output = './' + dir_path + '/multilingual/c4_dataset.' + lang

print(file_path)

#for i in range(3, int(number_of_corpora)+1):
data = pd.read_json(file_path, lines=True)
data.to_csv(file_path_output, index=False, mode = 'a')
