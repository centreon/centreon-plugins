package Paws::S3::CopyObjectResult {
  use Moose;
  has ETag => (is => 'ro', isa => 'Str');
  has LastModified => (is => 'ro', isa => 'Str');
}
1;
