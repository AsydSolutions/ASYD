![ASYD Logo](https://raw.githubusercontent.com/AsydSolutions/ASYD/master/static/lib/img/asyd-logo.png)

**[ASYD](http://www.asyd.eu/) is the easiest server deployment automation system.
Powerful, versatile, agentless and fully opensource, with integrated web interface and monitoring.**


Installation on Debian:

	apt-get update && apt-get install -y ruby-full git libxslt-dev libxml2-dev libsqlite3-dev zlib1g-dev make gcc patch
	gem install bundler

	git clone https://github.com/AsydSolutions/asyd.git

	cd asyd
	bundle install

Or read the full [installation](https://github.com/AsydSolutions/asyd/blob/master/static/doc/en/installing.md) instructions.

Run ASYD:

	./asyd.sh start

Then open [http://localhost:3000/](http://localhost:3000/)

You can read the console output on `log/asyd.log`


**Please read the [Documentation](https://www.asyd.eu/documentation)**
