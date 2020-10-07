# Copyright 2014-2020 Mitchell. See LICENSE.

ta = ../..
ta_src = $(ta)/src
ta_lua = $(ta_src)/lua/src

CC = gcc
CFLAGS = -fPIC
LDFLAGS = -Wl,--retain-symbols-file -Wl,$(ta_src)/lua.sym
libyaml_flags = -Ilibyaml -DYAML_VERSION_MAJOR=0 -DYAML_VERSION_MINOR=2 \
  -DYAML_VERSION_PATCH=5 -D'YAML_VERSION_STRING="0.2.5"'
lyaml_flags = -Ilibyaml -D'VERSION="0.2.5"' -Ilyaml

all: yaml.so yaml.dll yamlosx.so
clean: ; rm -f *.o *.so *.dll

# Platform objects.

CROSS_WIN = i686-w64-mingw32-
CROSS_OSX = x86_64-apple-darwin17-cc

libyaml_objs = \
  api.o dumper.o emitter.o loader.o parser.o reader.o scanner.o writer.o
libyaml_win_objs = $(addsuffix -win.o, $(basename $(libyaml_objs)))
libyaml_osx_objs = $(addsuffix -osx.o, $(basename $(libyaml_objs)))
lyaml_objs = lemitter.o lparser.o lscanner.o lyaml.o
lyaml_win_objs = $(addsuffix -win.o, $(basename $(lyaml_objs)))
lyaml_osx_objs = $(addsuffix -osx.o, $(basename $(lyaml_objs)))

yaml.so: $(libyaml_objs) $(lyaml_objs)
	$(CC) -shared $(CFLAGS) -o $@ $^ $(LDFLAGS)
yaml.dll: $(libyaml_win_objs) $(lyaml_win_objs) lua.la
	$(CROSS_WIN)$(CC) -shared $(CFLAGS) -o $@ $^ $(LDFLAGS)
yamlosx.so: $(libyaml_osx_objs) $(lyaml_osx_objs)
	$(CROSS_OSX) -shared $(CFLAGS) -undefined dynamic_lookup -o $@ $^

$(libyaml_objs): %.o: libyaml/%.c ; $(CC) -c $(CFLAGS) $(libyaml_flags) $< -o $@
$(lyaml_objs): l%.o: lyaml/%.c
	$(CC) -c $(CFLAGS) $(lyaml_flags) -I$(ta_lua) $< -o $@
$(libyaml_win_objs): %-win.o: libyaml/%.c
	$(CROSS_WIN)$(CC) -c $(CFLAGS) $(libyaml_flags) $< -o $@
$(lyaml_win_objs): l%-win.o: lyaml/%.c
	$(CROSS_WIN)$(CC) -c $(CFLAGS) $(lyaml_flags) -DLUA_BUILD_AS_DLL -DLUA_LIB \
		-I$(ta_lua) $< -o $@
$(libyaml_osx_objs): %-osx.o: libyaml/%.c
	$(CROSS_OSX) -c $(CFLAGS) $(libyaml_flags) $< -o $@
$(lyaml_osx_objs): l%-osx.o: lyaml/%.c
	$(CROSS_OSX) -c $(CFLAGS) $(lyaml_flags) -I$(ta_lua) $< -o $@

lua.def:
	echo LIBRARY \"textadept.exe\" > $@ && echo EXPORTS >> $@
	grep -v "^#" $(ta_src)/lua.sym >> $@
lua.la: lua.def ; $(CROSS_WIN)dlltool -d $< -l $@

# Documentation.

cwd = $(shell pwd)
docs: luadoc README.md
README.md: init.lua
	cd $(ta)/scripts && luadoc --doclet markdowndoc $(cwd)/$< > $(cwd)/$@
	sed -i -e '1,+4d' -e '6c# YAML' -e '7d' -e 's/^##/#/;' $@
luadoc: init.lua
	cd $(ta)/modules && luadoc -d $(cwd) --doclet lua/tadoc $(cwd)/$< \
		--ta-home=$(shell readlink -f $(ta))
	sed -i 's/_HOME.\+\?_HOME/_HOME/;' tags

# External LibYAML and lyaml dependencies.

deps: libyaml lyaml

libyaml_zip = 0.2.5.zip
$(libyaml_zip): ; wget https://github.com/yaml/libyaml/archive/$@
libyaml: | $(libyaml_zip) ; unzip -d $@ -j $| "*/src/*" "*/include/*.h"
lyaml_zip = v6.2.6.zip
$(lyaml_zip): ; wget https://github.com/gvvaughan/lyaml/archive/$@
lyaml: | $(lyaml_zip) ;
	unzip -d $@ -j $| "*/ext/yaml/*" "*/lib/$@/*"
	sed -i "s/require 'lyaml/require 'yaml.lyaml/;" $@/*.lua
	sed -i "s/require 'yaml'/not OSX and require 'yaml.yaml' or require 'yaml.yamlosx'/;" $@/*.lua
	cd $@ && patch -p0 < ../lyaml.patch

# Releases.

ifneq (, $(shell hg summary 2>/dev/null))
  archive = hg archive -X ".hg*" $(1)
else
  archive = git archive HEAD --prefix $(1)/ | tar -xf -
endif

release: yaml | $(libyaml_zip) $(lyaml_zip)
	cp $| $<
	make -C $< deps && make -C $< -j ta="../../.."
	zip -r $<.zip $< -x "*.zip" "*.c" "*.h" "*.o" "*.def" "*.la" "$</.git*" \
		"$</libyaml*" && rm -r $<
yaml: ; $(call archive,$@)
