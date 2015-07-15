
package Paws::EC2::CreateRoute {
  use Moose;
  has ClientToken => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'clientToken' );
  has DestinationCidrBlock => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'destinationCidrBlock' , required => 1);
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has GatewayId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'gatewayId' );
  has InstanceId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'instanceId' );
  has NetworkInterfaceId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'networkInterfaceId' );
  has RouteTableId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'routeTableId' , required => 1);
  has VpcPeeringConnectionId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'vpcPeeringConnectionId' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateRoute');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::CreateRouteResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateRoute - Arguments for method CreateRoute on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateRoute on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method CreateRoute.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateRoute.

As an example:

  $service_obj->CreateRoute(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ClientToken => Str

  

Unique, case-sensitive identifier you provide to ensure the idempotency
of the request. For more information, see How to Ensure Idempotency.










=head2 B<REQUIRED> DestinationCidrBlock => Str

  

The CIDR address block used for the destination match. Routing
decisions are based on the most specific match.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 GatewayId => Str

  

The ID of an Internet gateway or virtual private gateway attached to
your VPC.










=head2 InstanceId => Str

  

The ID of a NAT instance in your VPC. The operation fails if you
specify an instance ID unless exactly one network interface is
attached.










=head2 NetworkInterfaceId => Str

  

The ID of a network interface.










=head2 B<REQUIRED> RouteTableId => Str

  

The ID of the route table for the route.










=head2 VpcPeeringConnectionId => Str

  

The ID of a VPC peering connection.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateRoute in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

