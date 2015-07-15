package Paws::Glacier::VaultAccessPolicy {
  use Moose;
  has Policy => (is => 'ro', isa => 'Str');
}
1;
