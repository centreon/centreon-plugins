use strict;
use warnings;

use Test::More;
use Test::Spelling;

if (!@ARGV) {
    die "Usage: perl pod_spell_check.t module.pm stopwords.t";
}

my $stopword_filename='tests/resources/spellcheck/stopwords.t';
if(defined($ARGV[1])){
    $stopword_filename=$ARGV[1];
}
open(FILE, "<", $stopword_filename)
    or die "Could not open $stopword_filename";
printf("Using dictionary: ".$stopword_filename." \n");

add_stopwords(<FILE>);
close(FILE);
set_spell_cmd('hunspell -l');
all_pod_files_spelling_ok($ARGV[0]);

