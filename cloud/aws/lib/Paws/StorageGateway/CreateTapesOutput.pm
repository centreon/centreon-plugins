
package Paws::StorageGateway::CreateTapesOutput {
  use Moose;
  has TapeARNs => (is => 'ro', isa => 'ArrayRef[Str]');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::CreateTapesOutput

=head1 ATTRIBUTES

=head2 TapeARNs => ArrayRef[Str]

  

A list of unique Amazon Resource Named (ARN) the represents the virtual
tapes that were created.











=cut

1;