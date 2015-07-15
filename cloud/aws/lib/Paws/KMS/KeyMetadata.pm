package Paws::KMS::KeyMetadata {
  use Moose;
  has AWSAccountId => (is => 'ro', isa => 'Str');
  has Arn => (is => 'ro', isa => 'Str');
  has CreationDate => (is => 'ro', isa => 'Str');
  has Description => (is => 'ro', isa => 'Str');
  has Enabled => (is => 'ro', isa => 'Bool');
  has KeyId => (is => 'ro', isa => 'Str', required => 1);
  has KeyUsage => (is => 'ro', isa => 'Str');
}
1;
