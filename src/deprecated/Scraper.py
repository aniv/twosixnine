# Scraper.py
# Fetches XML data from house.gov for all roll call votes

from bs4 import BeautifulSoup
import urllib2
from threading import Thread
import threading
from Queue import Queue


class Scraper:
	url_queue = None
	num_worker_threads = 10

	def __init__(self, threads):
		self.num_worker_threads = threads
		self.url_queue = Queue()

	def add_to_queue(self, url):
		print "Adding to URL queue: {0}".format(url)
		self.url_queue.put(url)

	def start_process_queue(self):
		for i in range(self.num_worker_threads):
		     t = Thread(target=self.worker)
		     t.daemon = True
		     t.start()
		self.url_queue.join()

	def worker(self):
		while True:
			url = self.url_queue.get()
			soup = self.scrape(url, True)
			data = self.parse(soup)
			self.load_data(data)
			self.url_queue.task_done()

	def scrape(self, url, soup=True):
		response = urllib2.urlopen(url)
		print "[{0}] Got response for {1}".format(threading.current_thread().name, url)
		# if (soup):
		# 	print self.make_soup(response.read())
		# else:
		# 	print response.read()

	def make_soup(self, document):
		return BeautifulSoup(document)

	def parse(self, soup):
		pass

	def load_data(self, data):
		pass



