
package Paws::EC2::AcceptVpcPeeringConnectionResult {
  use Moose;
  has VpcPeeringConnection => (is => 'ro', isa => 'Paws::EC2::VpcPeeringConnection', xmlname => 'vpcPeeringConnection', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::AcceptVpcPeeringConnectionResult

=head1 ATTRIBUTES

=head2 VpcPeeringConnection => Paws::EC2::VpcPeeringConnection

  

Information about the VPC peering connection.











=cut

