package Paws::KMS::AliasListEntry {
  use Moose;
  has AliasArn => (is => 'ro', isa => 'Str');
  has AliasName => (is => 'ro', isa => 'Str');
  has TargetKeyId => (is => 'ro', isa => 'Str');
}
1;
