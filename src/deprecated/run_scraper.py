from Scraper import Scraper
import threading, argparse

def main():
	parser = argparse.ArgumentParser(description='Fetches and parses data from House.gov for twosixtynine')
	parser.add_argument('-t','--threads', help='Number of threads for scraper', required=False)
	parser.add_argument('-y','--year', help='Year of Congress', required=True)
	parser.add_argument('-li','--limit', help='Inclusive limit on last vote number to be crawled in series (001 to {limit incl.})', required=True)
	args = parser.parse_args()

	limit = int(args.limit)
	year = args.year or '2011'
	threads = int(args.threads or 10)

	scraper = Scraper(threads)

	for i in xrange(1,limit+1):
		if i < 10:
			j = '00' + str(i)
		elif i < 100:
			j = '0' + str(i)
		elif i < 1000:
			j = str(i)
		scraper.add_to_queue('http://clerk.house.gov/evs/{0}/roll{1}.xml'.format(year, j))
	scraper.start_process_queue()

if __name__ == "__main__":
	main()