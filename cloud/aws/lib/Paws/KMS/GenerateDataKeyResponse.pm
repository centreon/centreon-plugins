
package Paws::KMS::GenerateDataKeyResponse {
  use Moose;
  has CiphertextBlob => (is => 'ro', isa => 'Str');
  has KeyId => (is => 'ro', isa => 'Str');
  has Plaintext => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::KMS::GenerateDataKeyResponse

=head1 ATTRIBUTES

=head2 CiphertextBlob => Str

  

Ciphertext that contains the encrypted data key. You must store the
blob and enough information to reconstruct the encryption context so
that the data encrypted by using the key can later be decrypted. You
must provide both the ciphertext blob and the encryption context to the
Decrypt API to recover the plaintext data key and decrypt the object.

If you are using the CLI, the value is Base64 encoded. Otherwise, it is
not encoded.









=head2 KeyId => Str

  

System generated unique identifier of the key to be used to decrypt the
encrypted copy of the data key.









=head2 Plaintext => Str

  

Plaintext that contains the data key. Use this for encryption and
decryption and then remove it from memory as soon as possible.











=cut

1;