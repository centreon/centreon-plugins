package Paws::CloudSearchDomain::Hits {
  use Moose;
  has cursor => (is => 'ro', isa => 'Str');
  has found => (is => 'ro', isa => 'Int');
  has hit => (is => 'ro', isa => 'ArrayRef[Paws::CloudSearchDomain::Hit]');
  has start => (is => 'ro', isa => 'Int');
}
1;
