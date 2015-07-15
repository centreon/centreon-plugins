
package Paws::KMS::DecryptResponse {
  use Moose;
  has KeyId => (is => 'ro', isa => 'Str');
  has Plaintext => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::KMS::DecryptResponse

=head1 ATTRIBUTES

=head2 KeyId => Str

  

ARN of the key used to perform the decryption. This value is returned
if no errors are encountered during the operation.









=head2 Plaintext => Str

  

Decrypted plaintext data. This value may not be returned if the
customer master key is not available or if you didn't have permission
to use it.











=cut

1;