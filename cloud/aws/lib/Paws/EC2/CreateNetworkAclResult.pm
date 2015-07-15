
package Paws::EC2::CreateNetworkAclResult {
  use Moose;
  has NetworkAcl => (is => 'ro', isa => 'Paws::EC2::NetworkAcl', xmlname => 'networkAcl', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateNetworkAclResult

=head1 ATTRIBUTES

=head2 NetworkAcl => Paws::EC2::NetworkAcl

  

Information about the network ACL.











=cut

