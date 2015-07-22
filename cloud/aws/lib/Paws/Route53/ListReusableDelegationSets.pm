
package Paws::Route53::ListReusableDelegationSets {
  use Moose;
  has Marker => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'marker' );
  has MaxItems => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'maxitems' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListReusableDelegationSets');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-04-01/delegationset');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53::ListReusableDelegationSetsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53::ListReusableDelegationSetsResponse

=head1 ATTRIBUTES

=head2 Marker => Str

  

If the request returned more than one page of results, submit another
request and specify the value of C<NextMarker> from the last response
in the C<marker> parameter to get the next page of results.









=head2 MaxItems => Str

  

Specify the maximum number of reusable delegation sets to return per
page of results.











=cut

