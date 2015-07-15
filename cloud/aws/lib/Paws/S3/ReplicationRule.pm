package Paws::S3::ReplicationRule {
  use Moose;
  has Destination => (is => 'ro', isa => 'Paws::S3::Destination', required => 1);
  has ID => (is => 'ro', isa => 'Str');
  has Prefix => (is => 'ro', isa => 'Str', required => 1);
  has Status => (is => 'ro', isa => 'Str', required => 1);
}
1;
