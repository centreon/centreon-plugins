package Paws::RedShift::Event {
  use Moose;
  has Date => (is => 'ro', isa => 'Str');
  has EventCategories => (is => 'ro', isa => 'ArrayRef[Str]');
  has EventId => (is => 'ro', isa => 'Str');
  has Message => (is => 'ro', isa => 'Str');
  has Severity => (is => 'ro', isa => 'Str');
  has SourceIdentifier => (is => 'ro', isa => 'Str');
  has SourceType => (is => 'ro', isa => 'Str');
}
1;
