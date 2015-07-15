
package Paws::EC2::CreateVpcResult {
  use Moose;
  has Vpc => (is => 'ro', isa => 'Paws::EC2::Vpc', xmlname => 'vpc', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateVpcResult

=head1 ATTRIBUTES

=head2 Vpc => Paws::EC2::Vpc

  

Information about the VPC.











=cut

