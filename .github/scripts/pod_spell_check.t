use strict;
use warnings;
use Test::Spelling;
use List::MoreUtils qw(uniq);

# the command must have at least one argument
if (!@ARGV) {
    die "Usage: perl pod_spell_check.t module.pm stopwords.t";
}
# the first argument is the module to check
my $module_to_check = $ARGV[0];

# the second (optional) argument is the additional dictionary
my $stopword_filename='tests/resources/spellcheck/stopwords.txt';
if(defined($ARGV[1])){
    $stopword_filename=$ARGV[1];
}

# get_stopwords(): reads the text file and returns its content as an array or strings
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

# get_module_options(): reads the Perl module file's POD and returns all the encountered --options
sub get_module_options {
    my ($module) = @_;

    my @cmd_result = `perldoc -T $module_to_check`;
    my @new_words;

    for my $pod_line (@cmd_result) {
        chomp $pod_line;
        my @parsed_options = $pod_line =~ /(--[\w-]+){1,}\s?/mg or next;
        push @new_words, @parsed_options;
    }

    return uniq(sort(@new_words));
}

my @known_words = get_stopwords($stopword_filename);
my @module_options = get_module_options($module_to_check);

# take all words from the text file and the module's options as valid words
add_stopwords(@known_words, @module_options);

# prepare the spelling check command
set_spell_cmd('hunspell -d en_US -l');

# check that all is correct in the Perl module file given as an argument
all_pod_files_spelling_ok($module_to_check);
