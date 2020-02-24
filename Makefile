SERVER_IP=127.1
SERVER_PORT=4006
SERVER_PID_FILE=.tmp/server.pid
SERVER_LOG_FILE=.tmp/server.log

build: ensure-post-author bundler
	bundle exec jekyll build

ensure-post-author:
	@find _posts/ -name '*.md' | xargs -I{} bash -c "grep -qP '^author: \w+' {} || ( echo 'No author found for {}' && exit 1 )"

pre-commit: build

test: $(SERVER_PID_FILE)
	@wget --mirror --output-document=mirror --quiet http://$(SERVER_IP):$(SERVER_PORT) \
		&& rm mirror \
		|| rm -f mirror && exit 1

start: .tmp build bundler
	@test -e $(SERVER_PID_FILE) \
		&& echo "$(SERVER_PID_FILE) already exists. The server is probably already running." && exit 1 \
		|| echo "Starting the server..."
	bundle exec jekyll serve --host $(SERVER_IP) --port $(SERVER_PORT) &> $(SERVER_LOG_FILE) & disown && echo $$! > $(SERVER_PID_FILE)

stop: $(SERVER_PID_FILE)
	kill `cat $(SERVER_PID_FILE)`
	@rm $(SERVER_PID_FILE) $(SERVER_LOG_FILE)

restart: stop build start

$(SERVER_PID_FILE):
	@echo "No $(SERVER_PID_FILE) file. The server is probably not running." && exit 1

.tmp:
	mkdir .tmp

purge:
	rm $(SERVER_PID_FILE)

post: bundler
	read -p "Article title: " title && bundle exec jekyll post "$$title"

# More jekyll-compose goodness, with `bundle exec`:
# jekyll page "My New Page"
# jekyll post "My New Post"
# jekyll draft "My new draft"
# jekyll publish _drafts/my-new-draft.md
# jekyll unpublish _posts/2014-01-24-my-new-draft.md

bundler: /usr/local/bin/bundle
/usr/local/bin/bundle:
	gem list bundler | grep '^bundler ' || gem install bundler
	bundle check || bundle install

edit:
	code -n .
e: edit

open:
	open http://$(SERVER_IP):$(SERVER_PORT)

fonts: _sass/_fonts.scss
_sass/_fonts.scss:
	( \
		echo 'https://fonts.googleapis.com/css?family=Alegreya+Sans|Alegreya:400,400i,700&display=swap&subset=cyrillic,latin-ext'; \
		echo 'https://fonts.googleapis.com/css?family=Alegreya+Sans:400,800,900&display=swap&subset=cyrillic,latin-ext' \
	) | while read url; do \
		curl \
			-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:69.0) Gecko/20100101 Firefox/69.0' \
			--fail "$$url" >> $@ \
	; done
	rm -rf assets/fonts
	mkdir -p assets/fonts
	grep -Po 'https://fonts.gstatic.com\S+.woff2' $@ | xargs wget --directory-prefix=assets/fonts/
	/usr/local/opt/gnu-sed/libexec/gnubin/sed -i 's|https://fonts.gstatic.com/.*/|fonts/|' $@

define GFONTS
endef
