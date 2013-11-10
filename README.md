twosixnine
==========

Data mining house.gov for fun and ~~profit~~ grades

## Prerequisites:
* [PeeWee](http://peewee.readthedocs.org/en/latest/peewee/quickstart.html)
* Queue, threading, argparse

## Gather data:

Get data from Govtrack by cloning their [congressional project](https://github.com/unitedstates/congress).
Follow instructions to setup & install the package. Then download the JSON data:

```
./run bills --bill_type=hres --congress=111
```

## Prepare data:

Process data obtained from Govtrack APIs

```
source env/bin/activate
pip install -r requirements.txt
python govtrack.py -d /Users/aniv/Dev/congress/data
```

