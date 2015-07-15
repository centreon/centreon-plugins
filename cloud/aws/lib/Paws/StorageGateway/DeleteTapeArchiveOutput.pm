
package Paws::StorageGateway::DeleteTapeArchiveOutput {
  use Moose;
  has TapeARN => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DeleteTapeArchiveOutput

=head1 ATTRIBUTES

=head2 TapeARN => Str

  

The Amazon Resource Name (ARN) of the virtual tape that was deleted
from the virtual tape shelf (VTS).











=cut

1;