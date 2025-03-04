#!/usr/bin/perl

use strict;
use warnings;
use Net::Curl::Easy qw(:constants);

# URL to fetch
my $url = 'https://www.centreon.com';

# Create a new Curl object
my $curl = Net::Curl::Easy->new();

# Prepare the request
$curl->setopt(CURLOPT_URL, $url);
my $response_body;
$curl->setopt(CURLOPT_WRITEDATA, \$response_body);

# Perform the request
eval {
    $curl->perform();
};
die "Unable to fetch URL $url: $@" if $@;

# Print the response body
print "Response body:\n$response_body\n";

print "Test completed successfully.\n";