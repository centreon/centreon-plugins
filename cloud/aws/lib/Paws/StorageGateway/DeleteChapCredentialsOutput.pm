
package Paws::StorageGateway::DeleteChapCredentialsOutput {
  use Moose;
  has InitiatorName => (is => 'ro', isa => 'Str');
  has TargetARN => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DeleteChapCredentialsOutput

=head1 ATTRIBUTES

=head2 InitiatorName => Str

  

The iSCSI initiator that connects to the target.









=head2 TargetARN => Str

  

The Amazon Resource Name (ARN) of the target.











=cut

1;