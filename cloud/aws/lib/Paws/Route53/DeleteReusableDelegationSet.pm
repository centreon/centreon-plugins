
package Paws::Route53::DeleteReusableDelegationSet {
  use Moose;
  has Id => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Id' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteReusableDelegationSet');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-04-01/delegationset/{Id}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'DELETE');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53::DeleteReusableDelegationSetResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53::DeleteReusableDelegationSetResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> Id => Str

  

The ID of the reusable delegation set you want to delete.











=cut

