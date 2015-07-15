package Paws::S3::Error {
  use Moose;
  has Code => (is => 'ro', isa => 'Str');
  has Key => (is => 'ro', isa => 'Str');
  has Message => (is => 'ro', isa => 'Str');
  has VersionId => (is => 'ro', isa => 'Str');
}
1;
