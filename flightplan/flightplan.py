import dlvhex

import re

# This benchmark requires the selenium package for Python.
# 
# Install:
#   wget https://pypi.python.org/packages/source/s/selenium/selenium-2.43.0.tar.gz
#   tar -zxvf selenium-2.43.0.tar.gz
#   cd selenium-2.43.0
#   sudo python setup.py install
# 
# Run:
#   dlvhex2 --pythonplugin=flightplan.py flightplan.hex instance1.hex
# 
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium import webdriver
from datetime import datetime

def getPrice(query):

	q = ""
	for stop in query:
		q = q + "/" + stop[0] + "-" + stop[1] + "/" + stop[2].strftime('%Y-%m-%d')

	# Start the WebDriver and load the page
	wd = webdriver.Firefox()
	wd.get("http://www.kayak.de/flights" + q)
	
	# Wait for the dynamically loaded elements to show up
	
	# And grab the page HTML source
	html_page = wd.page_source
	wd.quit()

	pattern = re.compile(u"bestPrice[^>]*>[0-9]+")
	minprice = -1
	for p in pattern.findall(html_page):
		price = int(p[p.index('>') + 1:])
		if minprice == -1 or price < minprice:
			minprice = price
	
	return minprice

def cost(query):
	sorted = []
	for stop in dlvhex.getInputAtoms():
		if (stop.isTrue()):
			index = stop.tuple()[1].intValue()
			while(len(sorted) <= index):
				sorted.append(0)
			sorted[index] = stop
	t = ()
	for stop in sorted:
		t = t + ( (stop.tuple()[2].value(), stop.tuple()[3].value(), datetime(stop.tuple()[4].intValue(), stop.tuple()[5].intValue(), stop.tuple()[6].intValue())), )
	price = getPrice(t)
	if price == -1:
		dlvhex.output(("error", ))
	else:
		dlvhex.output((price, ))

def register():
	dlvhex.addAtom("cost", (dlvhex.PREDICATE, ), 1)

