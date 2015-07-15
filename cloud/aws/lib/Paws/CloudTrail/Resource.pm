package Paws::CloudTrail::Resource {
  use Moose;
  has ResourceName => (is => 'ro', isa => 'Str');
  has ResourceType => (is => 'ro', isa => 'Str');
}
1;
