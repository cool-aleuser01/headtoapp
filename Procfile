#commented code for the thin server
#web: bundle exec thin -R config.ru start -p $PORT -e ${RACK_ENV:-development}
web: bundle exec unicorn -p $PORT -c ./unicorn.rb

