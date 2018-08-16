#!/bin/bash
#
# Centreon Plungins : create the fatpack plugin versions

# Needed on CentOS
# yum install perl-App-FatPacker

# Colors
RED='\033[1;31m'
NC='\033[0m'

# Copy common files
base()
{
	rm -rf fatpack/build
	mkdir -p fatpack/build/lib
	cp -R --parents centreon/plugins/{misc,mode,options,output,perfdata,script,statefile,values}.pm centreon/plugins/templates/ centreon/plugins/alternative/ fatpack/build/lib/
	cp centreon_plugins.pl fatpack/build/
	sed -i 's/alternative_fatpacker = 0/alternative_fatpacker = 1/' fatpack/build/lib/centreon/plugins/script.pm
	cp -R --parents $1 fatpack/build/lib/
}

# Copy pm files
processpm()
{
	local f
	for f in $(grep "^use .*centreon::" $1 | sed "s+.*centreon::+centreon::+; s+::+/+g; s+[);].*+.pm+")
	do
		processpm $f
		echo "Found pm $f"
		cp -f --parents $f fatpack/build/lib/ 2>/dev/null || echo -e "${RED}File not found${NC}"
	done
}

# Copy mode files
processmode()
{
	local f
	for f in $(sed '0,/$self->{modes}.*=/d;/);/,$d' $1 | sed '/^\s*#.*/d' | sed "s+.*=> '++;s+::+/+g;s+'.*+.pm+")
	do
		echo "Found mode $f"
		cp -f --parents $f fatpack/build/lib/ 2>/dev/null || echo -e "${RED}File not found${NC}"
	done
}

# Build fatpack script
build()
{
	find fatpack/build -name "*.pm" -exec sed -i ' /__END__/d' {} \;
	cd fatpack/build
	local name=${1//\//-}
	name=${name/-plugin.pm/.pl}
	fatpack file centreon_plugins.pl > ../$name
	cd - >/dev/null
	rm -rf fatpack/build
}

# Main
rm -rf fatpack
for plugin in $(find . -name plugin.pm -printf '%P\n')
do
	echo "### Processing $plugin"
	base $plugin
	processpm $plugin
	processmode $plugin
	build $plugin
	echo
done
