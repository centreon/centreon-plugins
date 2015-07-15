package Paws::CloudTrail::Event {
  use Moose;
  has CloudTrailEvent => (is => 'ro', isa => 'Str');
  has EventId => (is => 'ro', isa => 'Str');
  has EventName => (is => 'ro', isa => 'Str');
  has EventTime => (is => 'ro', isa => 'Str');
  has Resources => (is => 'ro', isa => 'ArrayRef[Paws::CloudTrail::Resource]');
  has Username => (is => 'ro', isa => 'Str');
}
1;
