
package Paws::Route53::ListHostedZonesByName {
  use Moose;
  has DNSName => (is => 'ro', isa => 'Str');
  has HostedZoneId => (is => 'ro', isa => 'Str');
  has MaxItems => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListHostedZonesByName');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-04-01/hostedzonesbyname');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53::ListHostedZonesByNameResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53::ListHostedZonesByNameResponse

=head1 ATTRIBUTES

=head2 DNSName => Str

  

The first name in the lexicographic ordering of domain names that you
want the C<ListHostedZonesByNameRequest> request to list.

If the request returned more than one page of results, submit another
request and specify the value of C<NextDNSName> and C<NextHostedZoneId>
from the last response in the C<DNSName> and C<HostedZoneId> parameters
to get the next page of results.









=head2 HostedZoneId => Str

  

If the request returned more than one page of results, submit another
request and specify the value of C<NextDNSName> and C<NextHostedZoneId>
from the last response in the C<DNSName> and C<HostedZoneId> parameters
to get the next page of results.









=head2 MaxItems => Str

  

Specify the maximum number of hosted zones to return per page of
results.











=cut

