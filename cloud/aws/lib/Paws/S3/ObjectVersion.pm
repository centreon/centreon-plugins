package Paws::S3::ObjectVersion {
  use Moose;
  has ETag => (is => 'ro', isa => 'Str');
  has IsLatest => (is => 'ro', isa => 'Bool');
  has Key => (is => 'ro', isa => 'Str');
  has LastModified => (is => 'ro', isa => 'Str');
  has Owner => (is => 'ro', isa => 'Paws::S3::Owner');
  has Size => (is => 'ro', isa => 'Int');
  has StorageClass => (is => 'ro', isa => 'Str');
  has VersionId => (is => 'ro', isa => 'Str');
}
1;
