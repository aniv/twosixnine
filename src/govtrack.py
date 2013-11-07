# Extracts features from JSON data obtained from Govtrack API
# for the purpose of predictive model building

import json, os, argparse

def extract_features(data):
	print data['bill_id'], data['official_title'], data['status']
	if len(data['cosponsors']) > 0:
		print reduce( lambda x, y: x + " " + y , map(lambda x: x['thomas_id'], data['cosponsors']) )
	print reduce (lambda x, y: x + " " + y, data['subjects'])
	print

def main():
	parser = argparse.ArgumentParser(description='Extracts features from JSON data obtained from Govtrack API')
	parser.add_argument('-d','--dir', help='path to Govtrack client data directory', required=True)
	args = parser.parse_args()

	data_directory = args.dir

	for congress_dir in os.listdir(data_directory):
		sub_path = data_directory + os.sep + congress_dir + os.sep + 'bills' + os.sep + 'hres'
		for bills_dir in os.listdir(sub_path):
			try:
				for data_file in filter(lambda d: d == 'data.json', os.listdir(sub_path + os.sep + bills_dir)):
					df = sub_path + os.sep + bills_dir + os.sep + data_file
					data = json.loads(open(df).read())
					extract_features(data)
			except OSError:
				continue


if __name__ == '__main__':
	main()