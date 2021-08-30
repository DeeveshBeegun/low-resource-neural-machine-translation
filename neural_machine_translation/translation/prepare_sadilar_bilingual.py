import sys
import string
import re

file_path = sys.argv[1]
src_lang = sys.argv[2]
tgt_lang = sys.argv[3]

for lang in [src_lang, tgt_lang]:

	with open(file_path + '.' + lang, 'r') as corpus:
		corpus_content = corpus.read()

		split_corpus = corpus_content.strip().split('\n')

		cleaned_corpus = []

		for line in split_corpus:
			
			# remove numbers enclosed by brackets e.g ( 3 ), ( 10 )
			line = re.sub(r'\((\s?[-+]?[0-9a-zA-Z]+\s?)\)', '', line)

			# remove all brackets
			line = re.sub(r'(\( | \))', '', line)

			# remove * in the corpus
			line = re.sub(r'\*\s', '', line)

			# remove continous occurence of '.'
			line = re.sub(r'[a-zA-Z\s]?\.{3,}', '', line)

			# remove continous occurence of '-'
			line = re.sub(r'[a-zA-Z\s]?\-{3,}', '', line)

			# remove extra space between words
			line = re.sub(r'\s+', ' ', line)

			cleaned_corpus.append(''.join(line)  + '\n')


		with open(file_path + '.' + lang + '.cleaned', 'w') as f:
			for line in cleaned_corpus:
				f.write(line)