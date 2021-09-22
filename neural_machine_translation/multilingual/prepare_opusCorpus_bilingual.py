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

                        # # remove text in the following forms: ( Titus 2 : 10 )
                        # line = re.sub(r'(\(\s[a-zA-Z]+\s[0-9]+\s:(\s[0-9]+\s\)|(\s[0-9]+-[0-9]+\s)\)))', '', line)

                        # remove icons and bullet points
                        line = re.sub(r'©\s|~W~O\s|~\~T\s|~@\s|~V\s|~^\s|~W\s|~V\s|\s~G|~W~F\s|~G\s', '', line)

                        # # remove anything that is contained in a bracket and the bracket itself
                        # # Ref: https://www.codegrepper.com/code-examples/python/python+remove+anything+in+brackets+from+string
                        # line = re.sub(r"[\(\[].*?[\)\]]", '', line)

                        # # remove the * character
                        # line = re.sub(r'\*', '', line)

                        # remove continous occurence of '.'
                        line = re.sub(r'[a-zA-Z\s]?\.{3,}', '', line)

                        # remove continous occurence of '.' followed by empty spaces
                        line = re.sub(r'(\s\.){3,}', '', line)

                        # remove continous occurence of '-'
                        line = re.sub(r'[a-zA-Z\s]?\-{3,}', '', line)

                        # remove extra space between words
                        line = re.sub(r'\s+', ' ', line)

                        cleaned_corpus.append(''.join(line)  + '\n')
                with open(file_path + '.' + lang + '.cleaned', 'w') as f:
                        for line in cleaned_corpus:
                                f.write(line)