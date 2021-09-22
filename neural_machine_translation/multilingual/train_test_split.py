import random
import sys
import glob
import os

def combine_datasets(file_parent_path, fileDir, src_lang, tgt_lang):
        for lang in [src_lang, tgt_lang]:

                with open(file_parent_path + '/combined_corpus.' + lang, 'w') as outputFile:
                        for path in fileDir:
                                path = path + '/*.' + lang + '.cleaned'
                                for filename in glob.glob(path):
                                        with open(filename) as infile:
                                                for line in infile:
                                                        outputFile.write(line)



def randomize_corpus(combined_corpus, src_lang, tgt_lang):

        for lang in [src_lang, tgt_lang]:
                lines = open(combined_corpus + '.' + lang).readlines()
                random.seed(1)
                random.shuffle(lines)
                open(combined_corpus + '.' + lang, 'w').writelines(lines)

def partition_dataset(combined_corpus, file_parent_path, src_lang, tgt_lang):

        for lang in [src_lang, tgt_lang]:
                with open(combined_corpus + '.' + lang, "r") as f:
                        data = f.read().split('\n')

                        train_data = data[:int((len(data)+1)*0.80)] # 80% training
                        test_data = data[int((len(data)+1)*0.80):] # 20% test test

                        f = open(file_parent_path + '/train.tags.' + src_lang + '-' + tgt_lang + '.' + lang, 'w')
                        f.write('\n'.join([str(i) for i in train_data]))

                        f.close()

                        f_test = open(file_parent_path + '/test.' + lang, 'w')
                        f_test.write('\n'.join([str(i) for i in test_data]))

                        f_test.close()

def main():

        fileDir = []

        file_parent_path = sys.argv[1]
        number_ofDatasets = sys.argv[2]
        for i in range(3, 3+int(number_ofDatasets)):
                fileDir.append(sys.argv[i])
        src_lang = sys.argv[3+int(number_ofDatasets)]
        tgt_lang = sys.argv[3+int(number_ofDatasets)+1]

        print(file_parent_path)
        print(fileDir)
        print(src_lang)
        print(tgt_lang)

        combined_corpus = file_parent_path + '/combined_corpus'

        combine_datasets(file_parent_path, fileDir, src_lang, tgt_lang)
        randomize_corpus(combined_corpus, src_lang, tgt_lang)
        partition_dataset(combined_corpus, file_parent_path, src_lang, tgt_lang)


if __name__=="__main__":
        main()