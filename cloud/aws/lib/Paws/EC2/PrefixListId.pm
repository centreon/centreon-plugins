package Paws::EC2::PrefixListId {
  use Moose;
  has PrefixListId => (is => 'ro', isa => 'Str', xmlname => 'prefixListId', traits => ['Unwrapped']);
}
1;
