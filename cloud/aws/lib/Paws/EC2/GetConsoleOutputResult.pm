
package Paws::EC2::GetConsoleOutputResult {
  use Moose;
  has InstanceId => (is => 'ro', isa => 'Str', xmlname => 'instanceId', traits => ['Unwrapped',]);
  has Output => (is => 'ro', isa => 'Str', xmlname => 'output', traits => ['Unwrapped',]);
  has Timestamp => (is => 'ro', isa => 'Str', xmlname => 'timestamp', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::GetConsoleOutputResult

=head1 ATTRIBUTES

=head2 InstanceId => Str

  

The ID of the instance.









=head2 Output => Str

  

The console output, Base64 encoded.









=head2 Timestamp => Str

  

The time the output was last updated.











=cut

