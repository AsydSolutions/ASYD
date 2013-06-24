Installation on Debian:

	apt-get update && apt-get install ruby rubygems git libxslt-dev libxml2-dev
	gem install bundler
	export PATH=/var/lib/gems/1.8/bin/:${PATH}

	git clone https://github.com/Choms/asyd.git

	cd asyd
	bundle install

Run ASYD:

	ruby asyd.rb

Then open [http://localhost:4567/](http://localhost:4567/)


**Please read the documentation on http://localhost:4567/help**
