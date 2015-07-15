package Paws::S3::Object {
  use Moose;
  has ETag => (is => 'ro', isa => 'Str');
  has Key => (is => 'ro', isa => 'Str');
  has LastModified => (is => 'ro', isa => 'Str');
  has Owner => (is => 'ro', isa => 'Paws::S3::Owner');
  has Size => (is => 'ro', isa => 'Int');
  has StorageClass => (is => 'ro', isa => 'Str');
}
1;
