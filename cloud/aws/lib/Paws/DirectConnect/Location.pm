package Paws::DirectConnect::Location {
  use Moose;
  has locationCode => (is => 'ro', isa => 'Str');
  has locationName => (is => 'ro', isa => 'Str');
}
1;
