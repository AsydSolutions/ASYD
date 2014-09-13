Installation on Debian:

	apt-get update && apt-get install ruby1.9.1-full git libxslt-dev libxml2-dev libsqlite3-dev make
	gem install bundler

	git clone https://github.com/AsydSolutions/asyd.git

	cd asyd
	bundle install

Or read the full [installation](https://github.com/AsydSolutions/asyd/blob/master/views/doc/en/installing.md) instructions.

Run ASYD:

	passenger start

Then open [http://localhost:3000/](http://localhost:3000/)


**Please read the [documentation](https://github.com/AsydSolutions/asyd/blob/master/views/doc/en/README.md)**

Use it at your own risk, is still on a very early development stage, might (and likely will) contain bugs
