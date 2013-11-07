# Vote.py
# Data representation of a House roll_call vote
# Elements defined in http://clerk.house.gov/evs/vote.dtd
# NOTE: We should study ^^ for better coding of these results

from bs4 import BeautifulSoup

class Vote:
	# Metadata for the bill
	metadata_majority = None
	metadata_congress = None
	metadata_session = None 
	metadata_chamber = None
	metadata_committee_name = None # Optional 
	metadata_rollcall_num = None # Optional
	metadata_legis_num = None # Optional
	metadata_vote_issue = None # Optional
	metadata_vote_question = None 
	metadata_vote_correction = None # Optional 
	metadata_amendment_num = None # Optional
	metadata_amendment_author = None # Optional
	metadata_vote_type = None
	metadata_vote_result = None
	metadata_action_date,action_time = None
	metadata_vote_desc = None # Optional
	metadata_vote_totals = None

	rollcall_num = None # ID in a given session of congress
	majority = None
	congress = None
	session = None 
	chamber = None
	committee_name = None
	committee_id = None # Optional or implied
	amending_committee_num = None # Implied, 1_5
	legis_num = None 
	

	def __init__(self, soup):
		pass

	def hydrate(self):
		pass

