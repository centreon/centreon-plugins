#!/bin/bash
#
# Centreon Plugins : create the fatpack versions



### --dyn-mode relations

DYN_MODES="
database/mssql/:apps/biztalk/sql
database/mysql/:apps/centreon/sql
database/mssql/:apps/jive/sql
database/mysql/:apps/jive/sql
database/oracle/:apps/jive/sql
database/postgres/:apps/jive/sql
"



#### Copy base plugin files

base()
{
	local m
	rm -rf fatpack/build
	mkdir -p fatpack/build/lib
	cp -R --parents $(dirname $1) fatpack/build/lib/
	for m in $DYN_MODES
	do
		if [[ "$(dirname $1)/" == *${m%:*}* ]]
		then
			echo "+ ${m#*:}"
			cp -R --parents ${m#*:} fatpack/build/lib/
		fi
	done
	find fatpack/build/lib/ -type f ! -name "*.pm" -delete
	cp centreon_plugins.pl fatpack/build/
}



### Find required pm files recursively

findpm()
{
	local f

	# Skip modules not in this files tree
	if [[ ! -f $1 ]]
	then
		return
	fi

	# Do not reprocess files
	if echo "$processedpm" | grep -q " $1 "
	then
		return
	fi
	processedpm="$processedpm$1 "

	# use/require pattern
	for f in $(grep -P "^\s*(use(?! lib)|require) (base )?(qw\()?(')?.*::" $1 | sed -E "s+^\s*(use|require) (base )?(qw\()?(')?++; s+::+/+g; s+[ ');].*+.pm+")
	do
		findpm $f
	done

	# (custom_)?modes pattern
	for f in $(awk -F\' '/^\s*%{ *\$self->{([a-z][a-z]*_)?modes} *} = \(/ {p=1} p && $4 {print} /);/ {p=0}' $1 | awk -F\' '! /^\s*#/ {gsub("::","/");print $4".pm"}')
	do
		findpm $f
	done

	# custom modes pattern
	for f in $(grep "\$self->{[a-z][a-z]*_modes}{[a-z][a-z]*} = '[^'][^']*';" $1 | awk -F\' '! /^\s*#/ {gsub("::","/");print $2".pm"}')
	do
		findpm $f
	done

	# defined components path pattern
	components_path=$(grep "\$self->{components_path} = '[^'][^']*';" $1 | awk -F\' '! /^\s*#/ {gsub("::","/");print $2}')
	if [[ -d "$components_path" ]]
	then
		for f in $components_path/*
		do
			findpm $f
		done
	fi
}



### Copy required pm files

processpm()
{
	local f
	processedpm=" "
	for f in $(find fatpack/build/ -type f | sed -E 's+fatpack/build/(lib/)?++')
	do
		findpm $f
	done
	for f in $processedpm
	do
		if [[ "$f" == *.pm ]] && [[ ! -f fatpack/build/lib/$f ]]
		then
			echo "+ $f"
			cp -f --parents $f fatpack/build/lib/
		fi
	done
}



### Build fatpack script

build()
{
	sed -i 's/alternative_fatpacker = 0/alternative_fatpacker = 1/' fatpack/build/lib/centreon/plugins/script.pm
	find fatpack/build -name "*.pm" -exec sed -i ' /__END__/d' {} \;
	local name=${1//\//-}
	name=${name/-plugin.pm/.pl}
	cd fatpack/build
	fatpack file centreon_plugins.pl > ../$name
	cd - >/dev/null
	rm -rf fatpack/build
}



### Main

if ! which fatpack >/dev/null 2>&1
then
	echo "You need App::FatPacker to continue."
	echo "On CentOS, just type: yum install perl-App-FatPacker"
	exit
fi
script_dir="$(cd $(dirname $0) && pwd)"
if [[ ! -f $script_dir/../centreon_plugins.pl ]]
then
	echo "$script_dir/../centreon_plugins.pl not found"
	exit
else
	start_dir=$(pwd)
	cd $script_dir/..
fi
rm -rf fatpack
for plugin in $(find . -name plugin.pm -printf '%P\n')
do
	echo "# "$(dirname $plugin)
	base $plugin
	processpm
	build $plugin
	echo
done
cd $start_dir
