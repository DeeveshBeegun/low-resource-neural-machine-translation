import sys
import string
import re
import glob

# file_path = sys.argv[1]
# lang = sys.argv[2]

memat_dir = sys.argv[1]

def combine_memat(src_lang, tgt_lang):

        for lang in [src_lang, tgt_lang]:

                memat_filenames = glob.glob(memat_dir+"/*/*."+lang)
                print(memat_filenames)

                with open('combined_memat.' + lang, 'w') as outputFile:                        
                	for name in memat_filenames:
                		with open(name) as infile:
                			for line in infile:
                				outputFile.write(line)


def clean_corpus(file_path):

	with open(file_path, 'r') as corpus:
		corpus_content = corpus.read()

		split_corpus = corpus_content.strip().split('\n')

		cleaned_corpus = []

		for line in split_corpus:
			
			line = re.sub(r'\(([\s]?[-+]?[0-9]+[\s]?)\)', '', line)

			line = re.sub(r'\(([\s]?[a-zA-Z][\s]?)\)', '', line)

			# # remove punctuations 
			# line = line.translate(str.maketrans('', '', string.punctuation))

			# remove extra space between words
			line = ' '.join(re.split(r'\s+', line)).strip()

			line = re.sub(r'\*', '', line)

			line = re.sub(r'[a-zA-Z]?\--+', '', line)

			line = re.sub(r'[a-zA-Z]?\...+', '', line)

			cleaned_corpus.append(''.join(line)  + '\n')

		with open('cleaned.' + lang, 'w') as f:
			for line in cleaned_corpus:
				f.write(line)

combine_memat('en', 'xh')
#clean_corpus('/parallel/combined_memat.en')
