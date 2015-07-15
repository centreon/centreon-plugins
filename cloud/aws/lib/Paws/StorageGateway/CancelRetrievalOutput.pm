
package Paws::StorageGateway::CancelRetrievalOutput {
  use Moose;
  has TapeARN => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::CancelRetrievalOutput

=head1 ATTRIBUTES

=head2 TapeARN => Str

  

The Amazon Resource Name (ARN) of the virtual tape for which retrieval
was canceled.











=cut

1;