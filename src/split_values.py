import MySQLdb
import urllib2, json, yaml

db = None
cosponsor_data = {}
thomas_to_govtrack = {}

def process_yamls():
	global thomas_to_govtrack
	current = open('../data/legislators-current.yaml', 'r')
	print "Processing current YAML"
	for leg in yaml.load(current):
		gt = leg['id'].get('govtrack', None)
		th = leg['id'].get('thomas', None)
		print (gt, th)
		if gt != None and th != None:
			thomas_to_govtrack[th] = gt

	historical = open('../data/legislators-historical-mod.yaml', 'r')
	print "Processing historical YAML"
	for leg in yaml.load(historical):
		gt = leg['id'].get('govtrack', None)
		th = leg['id'].get('thomas', None)
		print (gt, th)
		if gt != None and th != None:
			thomas_to_govtrack[th] = gt


def append_cosponsor_details(data):
	global cosponsor_data
	global db
	conn = db.cursor()

	for bill in data:
		for (bill_id, cosponsor_thomas) in bill:
			print "Working on bill_id {0}".format(bill_id)
			if cosponsor_thomas != '':
				if cosponsor_thomas not in cosponsor_data.keys():
					# fetch data from govtrack if not available locally
					print "Fetching data for {0}".format(cosponsor_thomas)
					try:
						cosponsor_govtrack = thomas_to_govtrack[cosponsor_thomas]
					except KeyError:
						print ">>> Could not find Thomas ID {0} in YAML data; skipping".format(cosponsor_thomas)
						continue
					gt = json.loads(urllib2.urlopen('https://www.govtrack.us/api/v2/person/{0}'.format(cosponsor_govtrack)).read())
					for role in gt['roles']:
						if role['congress_numbers'] is not None and (111 in role['congress_numbers'] or 112 in role['congress_numbers'] or 113 in role['congress_numbers']):
							cosponsor_data[cosponsor_thomas] = {}
							cosponsor_data[cosponsor_thomas]['party'] = role['party']
							cosponsor_data[cosponsor_thomas]['state'] = role['state']
				print "\tinserting.."
				conn.execute("""INSERT INTO bill_cosponsors (bill_id, cosponsor_id, cosponsor_gt_id, cosponsor_party, cosponsor_state) VALUES ("%s", "%s", "%s", "%s", "%s")""" % tuple([bill_id, cosponsor_thomas, thomas_to_govtrack[cosponsor_thomas], cosponsor_data[cosponsor_thomas]['party'], cosponsor_data[cosponsor_thomas]['state']]))

def append_subject_details(data):
	global db
	conn = db.cursor()
	i = 0

	for bill in data:
		i += 1
		print "Bill counter: {0}".format(i)
		for bill_topics in bill:
			bill_id = bill_topics[0]
			subject = bill_topics[1]
			conn.execute("""INSERT INTO bill_subjects (bill_id, subject) VALUES ("%s", "%s")""" % tuple([bill_id,subject]) )


def split_cosponsors():
	global db
	bill_cosponsors = []
	conn = db.cursor()
	conn.execute("""SELECT bill_id, cosponsor_ids FROM raw_bill_data""")
	while True:
		row = conn.fetchone()
		if row == None:
			break
		else:
			bill_id = row[0]
			cosponsors = row[1]
			cosponsors = cosponsors.split('|')
			bill_cosponsors.append(zip((bill_id,)*len(cosponsors), cosponsors))
	return bill_cosponsors

def split_subjects():
	global db
	bill_subjects = []
	conn = db.cursor()
	print "Running SQL"
	conn.execute("""SELECT bill_id, subjects FROM raw_bill_data""")
	print "Processing data"
	while True:
		row = conn.fetchone()
		if row == None:
			break
		else:
			if len(row) > 1:
				bill_id = row[0]
				subjects = row[1]
				subjects = subjects.split('|')
				bill_subjects.append(zip((bill_id,)*len(subjects), subjects))
			else:
				bill_id = row[0]
				subjects = ""
				bill_subjects.append((bill_id, subjects))
	return bill_subjects

def main():
	global db
	credentials = json.loads(open('credentials.json').read())
	db = MySQLdb.connect(db=credentials['db'], host=credentials['host'], user=credentials['user'], passwd=credentials['password'])
	# process_yamls()

	# data = split_cosponsors()
	# print data
	# print append_cosponsor_details(data)

	data = split_subjects()
	append_subject_details(data)


if __name__ == "__main__":
	main()