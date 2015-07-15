
package Paws::EC2::RestoreAddressToClassicResult {
  use Moose;
  has PublicIp => (is => 'ro', isa => 'Str', xmlname => 'publicIp', traits => ['Unwrapped',]);
  has Status => (is => 'ro', isa => 'Str', xmlname => 'status', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::RestoreAddressToClassicResult

=head1 ATTRIBUTES

=head2 PublicIp => Str

  

The Elastic IP address.









=head2 Status => Str

  

The move status for the IP address.











=cut

