import sys
import string
import re

file_path = sys.argv[1]
lang = sys.argv[2]

with open(file_path, 'r') as corpus:
	corpus_content = corpus.read()

	split_corpus = corpus_content.strip().split('\n')

	cleaned_corpus = []

	for line in split_corpus:
		
		# remove numbers enclosed by brackets e.g ( 3 ), ( 10 )
		line = re.sub(r'\(([\s]?[-+]?[0-9]+[\s]?)\)', '', line)

		# remove alphabet enclosed by brackets e.g ( a )
		line = re.sub(r'\(([\s]?[a-zA-Z][\s]?)\)', '', line)

		# remove extra space between words
		line = ' '.join(re.split(r'\s+', line)).strip()

		# remove * in the corpus
		line = re.sub(r'\*', '', line)

		# remove continous occurence of '-'
		line = re.sub(r'[a-zA-Z]?\--+', '', line)

		# remove continous occurence of '.'
		line = re.sub(r'[a-zA-Z]?\...+', '', line)

		cleaned_corpus.append(''.join(line)  + '\n')

	with open('cleaned.' + lang, 'w') as f:
		for line in cleaned_corpus:
			f.write(line)