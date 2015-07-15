package Paws::S3::MultipartUpload {
  use Moose;
  has Initiated => (is => 'ro', isa => 'Str');
  has Initiator => (is => 'ro', isa => 'Paws::S3::Initiator');
  has Key => (is => 'ro', isa => 'Str');
  has Owner => (is => 'ro', isa => 'Paws::S3::Owner');
  has StorageClass => (is => 'ro', isa => 'Str');
  has UploadId => (is => 'ro', isa => 'Str');
}
1;
