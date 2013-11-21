insert into cosponsor_counts (bill_id, cosponsor_r, cosponsor_d)
select r.bill_id, r.cosponsor_r, d.cosponsor_d
from
	(select bill_id, votes as cosponsor_r
	from
		(select bill_id, cosponsor_party, count(*) as votes
			from bill_cosponsors
			group by bill_id, cosponsor_party) x 
	where x.cosponsor_party = "Republican") r
left outer join
	(select bill_id, votes as cosponsor_d
	from
		(select bill_id, cosponsor_party, count(*) as votes
		from bill_cosponsors
		group by bill_id, cosponsor_party) x
	where x.cosponsor_party = "Democrat") d
on r.bill_id = d.bill_id

union

select d.bill_id, r.cosponsor_r, d.cosponsor_d
from
	(select bill_id, votes as cosponsor_d
	from
		(select bill_id, cosponsor_party, count(*) as votes
		from bill_cosponsors
		group by bill_id, cosponsor_party) x
	where x.cosponsor_party = "Democrat") d
left outer join
	(select bill_id, votes as cosponsor_r
	from
		(select bill_id, cosponsor_party, count(*) as votes
			from bill_cosponsors
			group by bill_id, cosponsor_party) x 
	where x.cosponsor_party = "Republican") r
on d.bill_id = r.bill_id;


insert into cosponsor_counts (bill_id, cosponsor_r, cosponsor_d)
select x.bill_id, 0, 0
from raw_bill_data x
where x.cosponsor_ids = "";

select bill_id from cosponsor_counts
where bill_id not in 
  (select bill_id from raw_bill_data);