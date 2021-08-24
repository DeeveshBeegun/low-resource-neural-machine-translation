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

		# remove text in the following forms: ( Titus 2 : 10 )
		line = re.sub(r'(\(\s[a-zA-Z]+\s[0-9]+\s:(\s[0-9]+\s\)|(\s[0-9]+-[0-9]+\s)\)))', '', line)

		# remove icons and bullet points
		line = re.sub(r'©\s|●\s|✔\s|•\s|▪\s|➤\s|◯\s|□\s|\s⇩', '', line)

		# remove anything that is contained in a bracket and the bracket itself
		# Ref: https://www.codegrepper.com/code-examples/python/python+remove+anything+in+brackets+from+string
		line = re.sub(r"[\(\[].*?[\)\]]", '', line)

		# remove the * character 
		line = re.sub(r'\*', '', line)

		#line = re.sub(r'\.{3,}|\s[\.{3,}\s]+', '', line)

		line = re.sub(r'([\t ]*(?:\r?\n|\r))+', '', line)

		#line = re.sub(r'[a-zA-Z]?\--+', '', line)

		#line = re.sub(r'[a-zA-Z]?\...+', '', line)

		cleaned_corpus.append(''.join(line)  + '\n')

	with open('cleaned.' + lang, 'w') as f:
		for line in cleaned_corpus:
			f.write(line)
