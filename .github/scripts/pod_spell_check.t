use strict;
use warnings;
use Test::More;

use Test::Spelling;

open(FILE, "<", "stopwords.t");
add_stopwords(<FILE>);
close(FILE);

set_spell_cmd('hunspell -l');
all_pod_files_spelling_ok( $ARGV[0]);