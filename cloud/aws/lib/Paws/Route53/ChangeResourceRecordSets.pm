
package Paws::Route53::ChangeResourceRecordSets {
  use Moose;
  has ChangeBatch => (is => 'ro', isa => 'Paws::Route53::ChangeBatch', required => 1);
  has HostedZoneId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Id' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ChangeResourceRecordSets');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-04-01/hostedzone/{Id}/rrset/');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53::ChangeResourceRecordSetsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53::ChangeResourceRecordSetsResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> ChangeBatch => Paws::Route53::ChangeBatch

  

A complex type that contains an optional comment and the C<Changes>
element.









=head2 B<REQUIRED> HostedZoneId => Str

  

The ID of the hosted zone that contains the resource record sets that
you want to change.











=cut

