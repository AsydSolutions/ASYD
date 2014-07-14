Installation on Debian:

	apt-get update && apt-get install ruby1.9.1-full git libxslt-dev libxml2-dev libsqlite3-dev make
	gem install bundler

	git clone https://github.com/AsydSolutions/asyd.git

	cd asyd
	bundle install

Run ASYD:

	passenger start

Then open [http://localhost:3000/](http://localhost:3000/)


**Please read the [documentation](https://github.com/AsydSolutions/asyd/blob/master/views/help.md)**

Also, don't use it in production systems, is still on a very early development stage, might (and likely will) contain bugs
