package Paws::S3::ObjectIdentifier {
  use Moose;
  has Key => (is => 'ro', isa => 'Str', required => 1);
  has VersionId => (is => 'ro', isa => 'Str');
}
1;
