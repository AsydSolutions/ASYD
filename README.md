Installation on Debian:

	apt-get update && apt-get install ruby1.9.1-full git libxslt-dev libxml2-dev libsqlite3-dev
	gem install bundler
	export PATH=/var/lib/gems/1.9.1/bin/:${PATH}

	git clone https://github.com/Choms/asyd.git

	cd asyd
	bundle install

Run ASYD:

	rakup

Then open [http://localhost:9292/](http://localhost:9292/)


**Please read the [documentation](https://github.com/Choms/asyd/blob/master/views/help.md)**

And FFS, don't use it in production systems, is still on a very early development stage
