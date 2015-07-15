package Paws::Route53::ResourceTagSet {
  use Moose;
  has ResourceId => (is => 'ro', isa => 'Str');
  has ResourceType => (is => 'ro', isa => 'Str');
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::Route53::Tag]');
}
1;
