use strict;
use warnings;

use Test::More;
use Test::Spelling;

if (!@ARGV) {
    die "Missing perl file to check.";
}

my $stopword_filename='tests/resources/spellcheck/stopwords.t';
if(defined($ARGV[1])){
    $stopword_filename=$ARGV[1];
}
open(FILE, "<", $stopword_filename)
    or die "Could not open $stopword_filename";
printf("stopword file use : ".$stopword_filename." \n");

add_stopwords(<FILE>);
set_spell_cmd('hunspell -l');
all_pod_files_spelling_ok($ARGV[0]);
close(FILE);
