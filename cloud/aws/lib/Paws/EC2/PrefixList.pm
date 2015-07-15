package Paws::EC2::PrefixList {
  use Moose;
  has Cidrs => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'cidrSet', traits => ['Unwrapped']);
  has PrefixListId => (is => 'ro', isa => 'Str', xmlname => 'prefixListId', traits => ['Unwrapped']);
  has PrefixListName => (is => 'ro', isa => 'Str', xmlname => 'prefixListName', traits => ['Unwrapped']);
}
1;
