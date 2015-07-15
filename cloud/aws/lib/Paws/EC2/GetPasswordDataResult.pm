
package Paws::EC2::GetPasswordDataResult {
  use Moose;
  has InstanceId => (is => 'ro', isa => 'Str', xmlname => 'instanceId', traits => ['Unwrapped',]);
  has PasswordData => (is => 'ro', isa => 'Str', xmlname => 'passwordData', traits => ['Unwrapped',]);
  has Timestamp => (is => 'ro', isa => 'Str', xmlname => 'timestamp', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::GetPasswordDataResult

=head1 ATTRIBUTES

=head2 InstanceId => Str

  

The ID of the Windows instance.









=head2 PasswordData => Str

  

The password of the instance.









=head2 Timestamp => Str

  

The time the data was last updated.











=cut

