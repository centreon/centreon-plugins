package Paws::KMS::GrantConstraints {
  use Moose;
  has EncryptionContextEquals => (is => 'ro', isa => 'Paws::KMS::EncryptionContextType');
  has EncryptionContextSubset => (is => 'ro', isa => 'Paws::KMS::EncryptionContextType');
}
1;
