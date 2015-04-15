![ASYD Logo](https://raw.githubusercontent.com/AsydSolutions/ASYD/master/static/lib/img/asyd-logo.png)

**[ASYD](http://www.asyd.eu/) is the easiest server deployment automation system.
Powerful, versatile, agentless and fully opensource, with integrated web interface and monitoring.**


Installation on Debian:

	apt-get update && apt-get install ruby1.9.1-full ruby1.9.1-dev git libxslt-dev libxml2-dev libsqlite3-dev make
	gem install bundler

	git clone https://github.com/AsydSolutions/asyd.git

	cd asyd
	bundle install

Or read the full [installation](https://github.com/AsydSolutions/asyd/blob/master/static/doc/en/installing.md) instructions.

Run ASYD:

	passenger start

Then open [http://localhost:3000/](http://localhost:3000/)


**Please read the documentation: [[English](https://github.com/AsydSolutions/asyd/blob/master/static/doc/en/README.md)] [[Spanish](https://github.com/AsydSolutions/asyd/blob/master/static/doc/es/README.md)] [[German](https://github.com/AsydSolutions/asyd/blob/master/static/doc/de/README.md)] [[Dutch](https://github.com/AsydSolutions/asyd/blob/master/static/doc/nl/README.md)]**

Use it at your own risk, is still on a very early development stage, might (and likely will) contain bugs
