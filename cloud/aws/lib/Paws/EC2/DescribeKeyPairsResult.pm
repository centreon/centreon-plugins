
package Paws::EC2::DescribeKeyPairsResult {
  use Moose;
  has KeyPairs => (is => 'ro', isa => 'ArrayRef[Paws::EC2::KeyPairInfo]', xmlname => 'keySet', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeKeyPairsResult

=head1 ATTRIBUTES

=head2 KeyPairs => ArrayRef[Paws::EC2::KeyPairInfo]

  

Information about one or more key pairs.











=cut

