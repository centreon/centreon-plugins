
package Paws::EC2::DescribeVpcPeeringConnectionsResult {
  use Moose;
  has VpcPeeringConnections => (is => 'ro', isa => 'ArrayRef[Paws::EC2::VpcPeeringConnection]', xmlname => 'vpcPeeringConnectionSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeVpcPeeringConnectionsResult

=head1 ATTRIBUTES

=head2 VpcPeeringConnections => ArrayRef[Paws::EC2::VpcPeeringConnection]

  

Information about the VPC peering connections.











=cut

