
package Paws::EC2::DescribeNetworkAclsResult {
  use Moose;
  has NetworkAcls => (is => 'ro', isa => 'ArrayRef[Paws::EC2::NetworkAcl]', xmlname => 'networkAclSet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeNetworkAclsResult

=head1 ATTRIBUTES

=head2 NetworkAcls => ArrayRef[Paws::EC2::NetworkAcl]

  

Information about one or more network ACLs.











=cut

