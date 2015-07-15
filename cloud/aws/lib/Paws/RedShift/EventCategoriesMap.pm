package Paws::RedShift::EventCategoriesMap {
  use Moose;
  has Events => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::EventInfoMap]');
  has SourceType => (is => 'ro', isa => 'Str');
}
1;
