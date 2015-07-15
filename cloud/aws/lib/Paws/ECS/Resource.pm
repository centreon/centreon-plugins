package Paws::ECS::Resource {
  use Moose;
  has doubleValue => (is => 'ro', isa => 'Num');
  has integerValue => (is => 'ro', isa => 'Int');
  has longValue => (is => 'ro', isa => 'Int');
  has name => (is => 'ro', isa => 'Str');
  has stringSetValue => (is => 'ro', isa => 'ArrayRef[Str]');
  has type => (is => 'ro', isa => 'Str');
}
1;
