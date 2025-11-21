#!/usr/bin/perl
use strict;
use warnings;
use JSON::Path;

# Sample Perl data structure
my $data = {
    store => {
        book => [
            { category => "reference", author => "Nigel Rees", title => "Sayings of the Century", price => 8.95 },
            { category => "fiction", author => "Evelyn Waugh", title => "Sword of Honour", price => 12.99 },
            { category => "fiction", author => "Herman Melville", title => "Moby Dick", isbn => "0-553-21311-3", price => 8.99 },
            { category => "fiction", author => "J. R. R. Tolkien", title => "The Lord of the Rings", isbn => "0-395-19395-8", price => 22.99 }
        ],
        bicycle => {
            color => "red",
            price => 19.95
        }
    }
};

# Create a JSON::Path object
my $jpath = JSON::Path->new('$.store.book[*].author');

# Find all authors
my @authors = $jpath->values($data);

# Print authors
print "Authors:\n";
foreach my $author (@authors) {
    print "$author\n";
}