
package Paws::KMS::ReEncryptResponse {
  use Moose;
  has CiphertextBlob => (is => 'ro', isa => 'Str');
  has KeyId => (is => 'ro', isa => 'Str');
  has SourceKeyId => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::KMS::ReEncryptResponse

=head1 ATTRIBUTES

=head2 CiphertextBlob => Str

  

The re-encrypted data. If you are using the CLI, the value is Base64
encoded. Otherwise, it is not encoded.









=head2 KeyId => Str

  

Unique identifier of the key used to re-encrypt the data.









=head2 SourceKeyId => Str

  

Unique identifier of the key used to originally encrypt the data.











=cut

1;