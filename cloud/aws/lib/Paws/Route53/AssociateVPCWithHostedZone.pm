
package Paws::Route53::AssociateVPCWithHostedZone {
  use Moose;
  has Comment => (is => 'ro', isa => 'Str');
  has HostedZoneId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Id' , required => 1);
  has VPC => (is => 'ro', isa => 'Paws::Route53::VPC', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AssociateVPCWithHostedZone');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2013-04-01/hostedzone/{Id}/associatevpc');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Route53::AssociateVPCWithHostedZoneResponse');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Route53::AssociateVPCWithHostedZoneResponse

=head1 ATTRIBUTES

=head2 Comment => Str

  

I<Optional:> Any comments you want to include about a
C<AssociateVPCWithHostedZoneRequest>.









=head2 B<REQUIRED> HostedZoneId => Str

  

The ID of the hosted zone you want to associate your VPC with.

Note that you cannot associate a VPC with a hosted zone that doesn't
have an existing VPC association.









=head2 B<REQUIRED> VPC => Paws::Route53::VPC

  

The VPC that you want your hosted zone to be associated with.











=cut

