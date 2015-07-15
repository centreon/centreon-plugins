package Paws::Config::ConfigurationItem {
  use Moose;
  has accountId => (is => 'ro', isa => 'Str');
  has arn => (is => 'ro', isa => 'Str');
  has availabilityZone => (is => 'ro', isa => 'Str');
  has configuration => (is => 'ro', isa => 'Str');
  has configurationItemCaptureTime => (is => 'ro', isa => 'Str');
  has configurationItemMD5Hash => (is => 'ro', isa => 'Str');
  has configurationItemStatus => (is => 'ro', isa => 'Str');
  has configurationStateId => (is => 'ro', isa => 'Str');
  has relatedEvents => (is => 'ro', isa => 'ArrayRef[Str]');
  has relationships => (is => 'ro', isa => 'ArrayRef[Paws::Config::Relationship]');
  has resourceCreationTime => (is => 'ro', isa => 'Str');
  has resourceId => (is => 'ro', isa => 'Str');
  has resourceType => (is => 'ro', isa => 'Str');
  has tags => (is => 'ro', isa => 'Paws::Config::Tags');
  has version => (is => 'ro', isa => 'Str');
}
1;
