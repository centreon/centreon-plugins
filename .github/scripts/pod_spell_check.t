use strict;
use warnings;
use Test::More;

use Test::Spelling;
use Pod::Wordlist;

add_stopwords(<DATA>);
set_spell_cmd('hunspell -L'); # current preferred
# set_spell_cmd('aspell list');
# set_spell_cmd('spell');
# set_spell_cmd('ispell -l');
my $cmd = has_working_spellchecker;
printf($cmd."\n");
all_pod_files_spelling_ok( $ARGV[0]);

__DATA__
SNMP
SSH