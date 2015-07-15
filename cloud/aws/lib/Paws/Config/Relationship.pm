package Paws::Config::Relationship {
  use Moose;
  has relationshipName => (is => 'ro', isa => 'Str');
  has resourceId => (is => 'ro', isa => 'Str');
  has resourceType => (is => 'ro', isa => 'Str');
}
1;
