.SUFFIXES: .js .pegjs .css .html .msc .mscin .msgenny .svg .png .jpg
PEGJS=node_modules/pegjs/bin/pegjs
GIT=git
NPM=npm
MAKEDEPEND=node_modules/.bin/js-makedepend --output-to jsdependencies.mk --exclude "node_modules|doc"
WEBPACK=node_modules/.bin/webpack
RJS=node_modules/.bin/r.js

GENERATED_SOURCES=src/parse/stategenny-parser.js \
	src/render/dot.states.template.js \
	src/render/dot.template.js \
	src/render/stategenny.template.js

dev-build: src/index.js src/lib/viz.js/viz.js doc/lib doc/lib/require.js

# production rules
src/parse/%-parser.js: src/parse/peg/%-parser.pegjs
	$(PEGJS) --format umd -o $@ $<

src/lib/viz.js/viz.js: node_modules/viz.js/viz.js
	cp $< $@

src/lib/handlebars.runtime.js: node_modules/handlebars/dist/handlebars.runtime.js
	cp $< $@

src/render/%.template.js: src/render/%.template.hbs
	handlebars --amd -h "../lib/" -f $@ $<
	sh utl/amdefinify.sh $@

public public/lib doc/lib:
	mkdir -p $@

public/stategenny-online-interpreter.js: $(ONLINE_INTERPRETER_SOURCES)
	$(RJS) -o baseUrl="./doc" \
			name="stategenny-online-interpreter" \
			out=$@ \
			preserveLicenseComments=true

public/index.html: doc/index.html public/stategenny-online-interpreter.js public/lib/require.js
	cp $< $@

public/lib/require.js doc/lib/require.js: node_modules/requirejs/require.js
	cp $< $@

# dependencies
include jsdependencies.mk

# executable targets
depend:
	$(MAKEDEPEND) --system amd,cjs src
	$(MAKEDEPEND) --append --system amd,cjs test
	$(MAKEDEPEND) --append --system amd --flat-define ONLINE_INTERPRETER_SOURCES doc/stategenny-online-interpreter.js

clean:
	rm -rf $(GENERATED_SOURCES)
	rm -rf coverage

check: dev-build
	$(NPM) run lint
	$(NPM) run nsp
	$(NPM) test
	$(NPM) outdated

pages: public/lib dev-build public/index.html

update-dependencies: run-update-dependencies clean dev-build check
	$(GIT) diff package.json

run-update-dependencies:
	$(NPM) run npm-check-updates
	$(NPM) install
