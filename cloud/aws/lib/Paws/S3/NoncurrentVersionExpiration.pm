package Paws::S3::NoncurrentVersionExpiration {
  use Moose;
  has NoncurrentDays => (is => 'ro', isa => 'Int');
}
1;
