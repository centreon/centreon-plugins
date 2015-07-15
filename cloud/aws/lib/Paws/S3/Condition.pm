package Paws::S3::Condition {
  use Moose;
  has HttpErrorCodeReturnedEquals => (is => 'ro', isa => 'Str');
  has KeyPrefixEquals => (is => 'ro', isa => 'Str');
}
1;
