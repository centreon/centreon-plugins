
use base qw(centreon::plugins::mode);
use strict;
use warnings;
use JSON;
use DateTime;
use centreon::plugins::http;

#Default Values

my %options = (
    hostname => '10.103.69.51',
    proto    => 'https',
    port     => 5665,
    method   => 'GET',
    urlpath  => 'v1/status',
    header   => $header,
    timeout => 3,
    nooptions => 1,
    insecure => 1,
    );
my $https_connection = centreon::plugins::http->new(%options);
# $https_connection->set_options(%options);
#my $webcontent = $https_connection->request();
#print($webcontent->{state_code_str});
# my $json = JSON->new();
# eval {
#     my $json_dict = $json->decode($webcontent);
# }
# if ($@) {
#     print ("Error decoding api response")
# }
# my $results = $json_dict->{results};
# print($json_dict->{results}[0]->{status}->{api('identity')};
print("\n");
