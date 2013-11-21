# govtrack_processor.py
# Multi-threaded queue-based Govtrack JSON processor

from threading import Thread
import threading
import MySQLdb
from Queue import Queue


class GovtrackProcessor:
	bill_queue = None
	num_worker_threads = None

	def __init__(self, extractor=None, loader=None, mysql=None, threads=None):
		"""
		Create a multi-threaded GovTrack JSON processor
		threads: Number of threads
		extractor: Method to extract features from bill JSON object
		"""
		self.bill_queue = Queue()

		if (threads != None):
			self.num_worker_threads = threads
		else:
			self.num_worker_threads = 10

		if (extractor != None):
			self.feature_extract = extractor
		else:
			self.feature_extract = self.default_feature_extractor

		if (loader != None):
			self.load_data = loader
		else:
			self.load_data = self.default_load_data

	def add_to_queue(self, bill):
		print "Adding to bill queue: {0}".format(bill)
		self.bill_queue.put(bill)

	def start_process_queue(self):
		for i in range(self.num_worker_threads):
		     t = Thread(target=self.worker)
		     t.daemon = True
		     t.start()
		self.bill_queue.join()

	def worker(self):
		db = MySQLdb.connect(db='twosixnine', host='twosixnine.code.aniv.info', user='stat701', passwd='d3anf0st3r')
		conn = db.cursor()
		while True:
			bill = self.bill_queue.get()
			features = self.feature_extract(bill)
			self.load_data(db, conn, features)
			self.bill_queue.task_done()
		conn.close()

	def default_feature_extractor(self, bill):
		raise Exception("Default feature extractor not implemented")

	def default_load_data(self, features):
		raise Exception("Data loader not implemented")




