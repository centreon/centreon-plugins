
package Paws::EC2::CreateVpnConnection {
  use Moose;
  has CustomerGatewayId => (is => 'ro', isa => 'Str', required => 1);
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Options => (is => 'ro', isa => 'Paws::EC2::VpnConnectionOptionsSpecification', traits => ['NameInRequest'], request_name => 'options' );
  has Type => (is => 'ro', isa => 'Str', required => 1);
  has VpnGatewayId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateVpnConnection');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::CreateVpnConnectionResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateVpnConnection - Arguments for method CreateVpnConnection on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateVpnConnection on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method CreateVpnConnection.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateVpnConnection.

As an example:

  $service_obj->CreateVpnConnection(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CustomerGatewayId => Str

  

The ID of the customer gateway.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 Options => Paws::EC2::VpnConnectionOptionsSpecification

  

Indicates whether the VPN connection requires static routes. If you are
creating a VPN connection for a device that does not support BGP, you
must specify C<true>.

Default: C<false>










=head2 B<REQUIRED> Type => Str

  

The type of VPN connection (C<ipsec.1>).










=head2 B<REQUIRED> VpnGatewayId => Str

  

The ID of the virtual private gateway.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateVpnConnection in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

