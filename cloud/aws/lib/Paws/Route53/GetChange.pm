
package Paws::Route53::GetChange {
  use Moose;
  has Id => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Id' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetChange');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-04-01/change/{Id}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53::GetChangeResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53::GetChangeResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> Id => Str

  

The ID of the change batch request. The value that you specify here is
the value that C<ChangeResourceRecordSets> returned in the Id element
when you submitted the request.











=cut

