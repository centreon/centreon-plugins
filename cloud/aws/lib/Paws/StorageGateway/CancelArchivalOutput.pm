
package Paws::StorageGateway::CancelArchivalOutput {
  use Moose;
  has TapeARN => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::CancelArchivalOutput

=head1 ATTRIBUTES

=head2 TapeARN => Str

  

The Amazon Resource Name (ARN) of the virtual tape for which archiving
was canceled.











=cut

1;