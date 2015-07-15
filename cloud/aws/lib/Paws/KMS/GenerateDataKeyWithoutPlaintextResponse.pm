
package Paws::KMS::GenerateDataKeyWithoutPlaintextResponse {
  use Moose;
  has CiphertextBlob => (is => 'ro', isa => 'Str');
  has KeyId => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::KMS::GenerateDataKeyWithoutPlaintextResponse

=head1 ATTRIBUTES

=head2 CiphertextBlob => Str

  

Ciphertext that contains the wrapped data key. You must store the blob
and encryption context so that the key can be used in a future decrypt
operation.

If you are using the CLI, the value is Base64 encoded. Otherwise, it is
not encoded.









=head2 KeyId => Str

  

System generated unique identifier of the key to be used to decrypt the
encrypted copy of the data key.











=cut

1;