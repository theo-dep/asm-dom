# if you are using windows, comment line 5, 6 and 7 and uncomment line 8, 9 and 10
# leave it as it was before committing as travis uses linux
SRCDIR := src
TESTDIR := test
SRCS := $(shell find $(SRCDIR) -name "*.js")
SRCSCPP := $(shell find $(SRCDIR) -name "*.cpp")
TEST_FILES := $(shell find $(TESTDIR) -name "*.cpp")
#SRCS := $(shell FORFILES /P $(SRCDIR) /S /M *.js /C "CMD /C ECHO @relpath")
#SRCSCPP := $(shell FORFILES /P $(SRCDIR) /S /M *.cpp /C "CMD /C ECHO @relpath")
#TEST_FILES := $(shell FORFILES /P $(TESTDIR) /S /M *.cpp /C "CMD /C ECHO @relpath")

ESDIR := es
LIBDIR := lib
ES := $(SRCS:$(SRCDIR)/%=$(ESDIR)/%)
LIBS := $(SRCS:$(SRCDIR)/%=$(LIBDIR)/%)
DISTDIR := dist
DISTJS := $(DISTDIR)/js
UMDJS := $(DISTJS)/asm-dom.js
TESTCPP := test/cpp/app.asm.js
COMPILED := compiled
COMPILEDASMJS := $(COMPILED)/asmjs
COMPILEDWASM := $(COMPILED)/wasm
CPPDIR := cpp

TREE := \
	$(COMPILED) \
	$(COMPILEDASMJS) \
	$(COMPILEDWASM) \
	$(DISTDIR) \
	$(DISTJS) \
	$(ESDIR) \
	$(LIBDIR) \
	$(sort $(patsubst %/,%,$(dir $(ES)))) \
	$(sort $(patsubst %/,%,$(dir $(LIBS))))

FILES = \
	src/cpp/asm-dom.cpp \
	src/cpp/asm-dom-server.cpp

CFLAGS = \
	-std=c++23 \
	-O3 \
	-Wall \
	-Werror \
	-pedantic \
	-Wno-deprecated \
	-Wno-parentheses \
	-Wno-format \
	-Wno-dollar-in-identifier-extension \
	-Wno-embedded-directive

EMCC_OPTIONS = \
	-Wno-unused-command-line-argument \
	-lembind \
	-sENVIRONMENT=node \
	-sMODULARIZE=1 \
	-sALLOW_MEMORY_GROWTH=1 \
	-sABORTING_MALLOC=1 \
	-sNO_EXIT_RUNTIME=1 \
	-sNO_FILESYSTEM=1 \
	-sDISABLE_EXCEPTION_CATCHING=2 \
	-sBINARYEN=1 \
	-sEXPORTED_RUNTIME_METHODS=[\'UTF8ToString\']

.PHONY: all install clean lint test test_js test_watch build

all: build

install:
	npm install

clean:
	npx rimraf $(DISTDIR) $(LIBDIR) $(ESDIR) $(CPPDIR) .nyc_output $(COMPILED) $(TESTCPP)

lint:
	npx eslint src test build

test: $(COMPILEDASMJS)/asm-dom.asm.js $(COMPILEDWASM)/asm-dom.js $(TESTCPP) test_js

test_js:
	npx cross-env BABEL_ENV=commonjs TEST_ENV=node mocha --require babel-register test/cpp/toHTML/toHTML.spec.js
	npx cross-env BABEL_ENV=commonjs TEST_ENV=node mocha --require babel-register test/js/toHTML.spec.js
	npx cross-env BABEL_ENV=commonjs nyc --require babel-register mocha --recursive

build: $(COMPILEDASMJS)/asm-dom.asm.js $(COMPILEDWASM)/asm-dom.js $(TESTCPP) $(LIBS) $(ES) $(UMDJS)
	npx ncp $(SRCDIR)/cpp $(CPPDIR)

$(TESTCPP): $(SRCSCPP) $(TEST_FILES)
	emcc \
		-DASMDOM_TEST \
		$(CFLAGS) \
		$(EMCC_OPTIONS) \
		-sWASM=0 \
		$(FILES) \
		$(TEST_FILES) \
		-o $@

.SECONDEXPANSION:
$(COMPILEDASMJS)/asm-dom.asm.js: $(SRCSCPP) | $$(@D)
	emcc \
		-DASMDOM_JS_SIDE \
		$(CFLAGS) \
		$(EMCC_OPTIONS) \
		-sWASM=0 \
		$(FILES) \
		src/js/index.cpp \
		-o $@

$(COMPILEDWASM)/asm-dom.js: $(SRCSCPP) | $$(@D)
	emcc \
		-DASMDOM_JS_SIDE \
		$(CFLAGS) \
		$(EMCC_OPTIONS) \
		-sWASM=1 \
		$(FILES) \
		src/js/index.cpp \
		-o $@

$(ESDIR)/%: $(SRCDIR)/% | $$(@D)
	npx cross-env BABEL_ENV=es babel $< --out-file $@

$(LIBDIR)/%: $(SRCDIR)/% | $$(@D)
	npx cross-env BABEL_ENV=commonjs babel $< --out-file $@

$(UMDJS): $(SRCS) | $$(@D)
	npx cross-env BABEL_ENV=commonjs webpack --env.prod --env WASM_PATH=$(COMPILEDWASM) src/js/index.js $@

$(TREE): %:
	npx mkdirp $@
