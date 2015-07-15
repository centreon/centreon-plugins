package Paws::S3::DeletedObject {
  use Moose;
  has DeleteMarker => (is => 'ro', isa => 'Bool');
  has DeleteMarkerVersionId => (is => 'ro', isa => 'Str');
  has Key => (is => 'ro', isa => 'Str');
  has VersionId => (is => 'ro', isa => 'Str');
}
1;
