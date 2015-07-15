package Paws::S3::DeleteMarkerEntry {
  use Moose;
  has IsLatest => (is => 'ro', isa => 'Bool');
  has Key => (is => 'ro', isa => 'Str');
  has LastModified => (is => 'ro', isa => 'Str');
  has Owner => (is => 'ro', isa => 'Paws::S3::Owner');
  has VersionId => (is => 'ro', isa => 'Str');
}
1;
