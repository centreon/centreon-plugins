package Paws::RDS::EventCategoriesMap {
  use Moose;
  has EventCategories => (is => 'ro', isa => 'ArrayRef[Str]');
  has SourceType => (is => 'ro', isa => 'Str');
}
1;
