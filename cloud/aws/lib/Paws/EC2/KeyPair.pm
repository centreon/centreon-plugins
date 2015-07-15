
package Paws::EC2::KeyPair {
  use Moose;
  has KeyFingerprint => (is => 'ro', isa => 'Str', xmlname => 'keyFingerprint', traits => ['Unwrapped',]);
  has KeyMaterial => (is => 'ro', isa => 'Str', xmlname => 'keyMaterial', traits => ['Unwrapped',]);
  has KeyName => (is => 'ro', isa => 'Str', xmlname => 'keyName', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::KeyPair

=head1 ATTRIBUTES

=head2 KeyFingerprint => Str

  

The SHA-1 digest of the DER encoded private key.









=head2 KeyMaterial => Str

  

An unencrypted PEM encoded RSA private key.









=head2 KeyName => Str

  

The name of the key pair.











=cut

