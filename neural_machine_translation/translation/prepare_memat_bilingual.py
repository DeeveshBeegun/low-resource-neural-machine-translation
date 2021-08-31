import sys
import string
import re
import glob

memat_dir = sys.argv[1]
src_lang = sys.argv[2]
tgt_lang = sys.argv[3]

def combine_memat(src_lang, tgt_lang):

        for lang in [src_lang, tgt_lang]:

                memat_filenames = glob.glob(memat_dir+'/MeMat/parallel'+"/*/*."+lang)

                with open(memat_dir + '/combined_memat.' + lang, 'w') as outputFile:                        
                	for name in memat_filenames:
                		with open(name) as infile:
                			for line in infile:
                				outputFile.write(line)


def clean_corpus(file_path):

	for lang in [src_lang, tgt_lang]:

		with open(file_path + '.' + lang, 'r') as corpus:
			corpus_content = corpus.read()

			split_corpus = corpus_content.strip().split('\n')

			cleaned_corpus = []

			for line in split_corpus:
				
				# # remove all text and numbers enclosed by brackets
				# line = re.sub(r'\((\s?[-+]?[0-9a-zA-Z]+\s?)\)', '', line)

				# # remove all numbers followed by dots
				# line = re.sub(r'[0-9]+.', '', line)

				# # remove single closed backets
				# line = re.sub(r'(\s?[-+]?[0-9a-zA-Z]+\s?)\)', '', line)

				# remove icons and bullet points
				line = re.sub(r'©\s|●\s|✔\s|•\s|▪\s|➤\s|◯\s|□\s|\s⇩|◆\s|⇨\s|\s', '', line)

				# # remove anything that is contained in a bracket and the bracket itself
				# # Ref: https://www.codegrepper.com/code-examples/python/python+remove+anything+in+brackets+from+string
				# line = re.sub(r"[\(\[].*?[\)\]]", '', line)

				# remove continous occurence of '.'
				line = re.sub(r'[a-zA-Z\s]?\.{3,}', '', line)

				# remove continous occurence of '.' followed by empty spaces
				line = re.sub(r'(\s\.){3,}', '', line)

				# remove continous occurence of '-'
				line = re.sub(r'[a-zA-Z\s]?\-{3,}', '', line)

				# remove extra space between words
				line = re.sub(r'\s+', ' ', line)

				cleaned_corpus.append(''.join(line)  + '\n')

			with open(file_path + lang + '.cleaned', 'w') as f:
				for line in cleaned_corpus:
					f.write(line)

combine_memat(src_lang, tgt_lang)
clean_corpus(memat_dir + '/combined_memat')
