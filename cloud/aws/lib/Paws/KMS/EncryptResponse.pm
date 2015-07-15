
package Paws::KMS::EncryptResponse {
  use Moose;
  has CiphertextBlob => (is => 'ro', isa => 'Str');
  has KeyId => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::KMS::EncryptResponse

=head1 ATTRIBUTES

=head2 CiphertextBlob => Str

  

The encrypted plaintext. If you are using the CLI, the value is Base64
encoded. Otherwise, it is not encoded.









=head2 KeyId => Str

  

The ID of the key used during encryption.











=cut

1;