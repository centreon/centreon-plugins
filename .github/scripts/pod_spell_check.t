use strict;
use warnings;
use Test::Spelling;

if (!@ARGV) {
    die "Usage: perl pod_spell_check.t module.pm stopwords.t";
}
my $module_to_check = $ARGV[0];
my $stopword_filename='tests/resources/spellcheck/stopwords.txt';
if(defined($ARGV[1])){
    $stopword_filename=$ARGV[1];
}

sub get_stopwords {
    my ($file) = @_;

    open(FILE, "<", $stopword_filename)
        or die "Could not open $stopword_filename";
    printf("Using dictionary: ".$stopword_filename." \n");
    my @stop_words;
    for my $line (<FILE>) {
        chomp $line;
        push @stop_words, $line;
    }
    close(FILE);

    return @stop_words;
}
sub get_module_options {
    my ($module) = @_;

    my @cmd_result = `perldoc -T $module_to_check`;
    my @new_words;
    for my $pod_line (@cmd_result) {
        chomp $pod_line;
        next if ($pod_line !~ /^\W*--([\w-]+)$/);
        push @new_words, "--$1";
    }

    return @new_words;
}

my @known_words = get_stopwords($stopword_filename);
my @module_options = get_module_options($module_to_check);

add_stopwords(@known_words, @module_options);

set_spell_cmd('hunspell -d en_US -l');
all_pod_files_spelling_ok($module_to_check);

