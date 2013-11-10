# Extracts features from JSON data obtained from Govtrack API
# for the purpose of predictive model building

import json, os, argparse
import MySQLdb
from govtrack_processor import GovtrackProcessor

# rds_db = MySQLdb.connect(db='twosixnine', host='twosixnine.cfhwd4wxhlyi.us-east-1.rds.amazonaws.com', user='stat', passwd='d3anf0ster')

def extract_features(data_file):
	data = json.loads(open(data_file).read())
	features = [ int(data['congress']), data['bill_id'], data['official_title'].replace('\'', '').replace('"','').replace(',', ''), data['status'] ]
	if len(data['cosponsors']) > 0:
		features.append(reduce( lambda x, y: x + "|" + y , map(lambda x: x['thomas_id'], data['cosponsors']) ))
	else:
		features.append("")
	features.append( reduce (lambda x, y: x.replace('\'', '').replace('"','') + "|" + y.replace('\'', '').replace('"',''), data['subjects']) )
	return features

def data_load(db, conn, features):
	# Assumes sequence of features matches to MySQL table definition
	# Be sure to modify schemas as required
	# print """INSERT INTO raw_bill_data VALUES (%d, "%s", "%s", "%s", "%s", "%s")""" % tuple(features)
	print "Loading bill {0}".format(features[1])
	s = conn.execute("""INSERT INTO raw_bill_data VALUES (%d, "%s", "%s", "%s", "%s", "%s")""" % tuple(features))
	db.commit()
	# print s


def main():
	# Parse cmd line arguments
	parser = argparse.ArgumentParser(description='Extracts features from JSON data obtained from Govtrack API')
	parser.add_argument('-d','--dir', help='path to Govtrack client data directory', required=True)
	args = parser.parse_args()
	data_directory = args.dir

	# Create multi-threaded Govtrack processor
	processor = GovtrackProcessor(extractor=extract_features, loader=data_load, mysql=None)

	# Add each data file to the processor queue
	for congress_dir in os.listdir(data_directory):
		sub_path = data_directory + os.sep + congress_dir + os.sep + 'bills' + os.sep + 'hres'
		for bills_dir in os.listdir(sub_path):
			try:
				for data_file in filter(lambda d: d == 'data.json', os.listdir(sub_path + os.sep + bills_dir)):
					df = sub_path + os.sep + bills_dir + os.sep + data_file
					processor.add_to_queue(df)
			except OSError:
				continue

	# Start processing!
	processor.start_process_queue()

if __name__ == '__main__':
	main()