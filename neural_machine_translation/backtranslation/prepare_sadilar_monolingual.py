import sys
import string
import re

file_path = sys.argv[1]


with open(file_path, 'r', encoding="utf-8") as corpus:
        corpus_content = corpus.read()

        split_corpus = corpus_content.strip().split('\n')

        cleaned_corpus = []

        for line in split_corpus:

                # # remove numbers enclosed by brackets e.g ( 3 ), ( 10 )
                # line = re.sub(r'\((\s?[-+]?[0-9a-zA-Z]+\s?)\)', '', line)

                # # remove all brackets
                # line = re.sub(r'(\( | \))', '', line)

                # # remove * in the corpus
                # line = re.sub(r'\*\s', '', line)

                # remove non ascii characters
                # Ref: https://stackoverflow.com/questions/20078816/replace-non-ascii-characters-with-a-single-space
                line = re.sub(r'[^\x00-\x7F]+',' ', line)

                # remove URLs
                # Ref: https://stackoverflow.com/questions/11331982/how-to-remove-any-url-within-a-string-in-python/11332580
                line = re.sub(r'^https?:\/\/.*[\r\n]*', '', line, flags=re.MULTILINE)

                # remove continous occurence of '.'
                line = re.sub(r'[a-zA-Z\s]?\.{3,}', '', line)

                # remove continuous occurence of '?'
                line = re.sub(r'\?{3,}', '', line)

                # remove continous occurence of '-'
                line = re.sub(r'[a-zA-Z\s]?\-{3,}', '', line)

                # remove extra space between words
                line = re.sub(r'\s+', ' ', line)
                
                cleaned_corpus.append(''.join(line)  + '\n')


        with open(file_path + '.cleaned', 'w') as f:
                for line in cleaned_corpus:
                        f.write(line)