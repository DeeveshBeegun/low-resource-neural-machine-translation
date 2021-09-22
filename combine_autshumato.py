import sys

src_lang = sys.argv[1]
tgt_lang = sys.argv[2]


def combine_datasets(file_parent_path, src_lang, tgt_lang):
	for lang in [src_lang, tgt_lang]:

		with open(file_parent_path + '/combined_autshumato.' + lang, 'w') as outputFile:
			for filename in glob.glob(file_parent_path):
				with open(filename) as infile:
					for line in infile:
						outputFile.write(line)

combine_datasets('Autshumato_MT_Evaluation_Set', src_lang, tgt_lang)