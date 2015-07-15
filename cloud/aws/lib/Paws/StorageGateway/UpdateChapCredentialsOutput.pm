
package Paws::StorageGateway::UpdateChapCredentialsOutput {
  use Moose;
  has InitiatorName => (is => 'ro', isa => 'Str');
  has TargetARN => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::UpdateChapCredentialsOutput

=head1 ATTRIBUTES

=head2 InitiatorName => Str

  

The iSCSI initiator that connects to the target. This is the same
initiator name specified in the request.









=head2 TargetARN => Str

  

The Amazon Resource Name (ARN) of the target. This is the same target
specified in the request.











=cut

1;