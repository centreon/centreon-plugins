package Paws::S3::NoncurrentVersionTransition {
  use Moose;
  has NoncurrentDays => (is => 'ro', isa => 'Int');
  has StorageClass => (is => 'ro', isa => 'Str');
}
1;
