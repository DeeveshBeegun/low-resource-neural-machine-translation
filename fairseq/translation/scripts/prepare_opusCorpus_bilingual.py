import sys
import string
import re
from unicodedata import normalize

file_path = sys.argv[1]
lang = sys.argv[2]

with open(file_path, 'r') as corpus:
	corpus_content = corpus.read()

	split_corpus = corpus_content.strip().split('\n')

	cleaned_corpus = []

	for line in split_corpus:
		
		# remove words enclosed by brackets e.g (123), ()
		line = re.sub(r'\([^)]*\)', '', line)

		# remove punctuations 
		line = line.translate(str.maketrans('', '', string.punctuation))

		# remove extra space between words
		line = ' '.join(re.split(r'\s+', line)).strip()

		cleaned_corpus.append(''.join(line)  + '\n')

	with open(file_path, 'w') as f:
		for line in cleaned_corpus:
			f.write(line)
