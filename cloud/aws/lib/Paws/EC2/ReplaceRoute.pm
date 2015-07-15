
package Paws::EC2::ReplaceRoute {
  use Moose;
  has DestinationCidrBlock => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'destinationCidrBlock' , required => 1);
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has GatewayId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'gatewayId' );
  has InstanceId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'instanceId' );
  has NetworkInterfaceId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'networkInterfaceId' );
  has RouteTableId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'routeTableId' , required => 1);
  has VpcPeeringConnectionId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'vpcPeeringConnectionId' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ReplaceRoute');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ReplaceRoute - Arguments for method ReplaceRoute on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method ReplaceRoute on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method ReplaceRoute.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ReplaceRoute.

As an example:

  $service_obj->ReplaceRoute(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DestinationCidrBlock => Str

  

The CIDR address block used for the destination match. The value you
provide must match the CIDR of an existing route in the table.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 GatewayId => Str

  

The ID of an Internet gateway or virtual private gateway.










=head2 InstanceId => Str

  

The ID of a NAT instance in your VPC.










=head2 NetworkInterfaceId => Str

  

The ID of a network interface.










=head2 B<REQUIRED> RouteTableId => Str

  

The ID of the route table.










=head2 VpcPeeringConnectionId => Str

  

The ID of a VPC peering connection.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ReplaceRoute in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

