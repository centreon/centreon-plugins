package Paws::RedShift::TaggedResource {
  use Moose;
  has ResourceName => (is => 'ro', isa => 'Str');
  has ResourceType => (is => 'ro', isa => 'Str');
  has Tag => (is => 'ro', isa => 'Paws::RedShift::Tag');
}
1;
