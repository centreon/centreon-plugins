package Paws::CloudSearchDomain::Bucket {
  use Moose;
  has count => (is => 'ro', isa => 'Int');
  has value => (is => 'ro', isa => 'Str');
}
1;
