
package Paws::EC2::CreateVpnGateway {
  use Moose;
  has AvailabilityZone => (is => 'ro', isa => 'Str');
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Type => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateVpnGateway');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::CreateVpnGatewayResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateVpnGateway - Arguments for method CreateVpnGateway on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateVpnGateway on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method CreateVpnGateway.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateVpnGateway.

As an example:

  $service_obj->CreateVpnGateway(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AvailabilityZone => Str

  

The Availability Zone for the virtual private gateway.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 B<REQUIRED> Type => Str

  

The type of VPN connection this virtual private gateway supports.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateVpnGateway in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

