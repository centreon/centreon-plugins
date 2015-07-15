package Paws::S3::Transition {
  use Moose;
  has Date => (is => 'ro', isa => 'Str');
  has Days => (is => 'ro', isa => 'Int');
  has StorageClass => (is => 'ro', isa => 'Str');
}
1;
