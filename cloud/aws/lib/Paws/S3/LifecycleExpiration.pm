package Paws::S3::LifecycleExpiration {
  use Moose;
  has Date => (is => 'ro', isa => 'Str');
  has Days => (is => 'ro', isa => 'Int');
}
1;
