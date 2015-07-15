package Paws::S3::CopyPartResult {
  use Moose;
  has ETag => (is => 'ro', isa => 'Str');
  has LastModified => (is => 'ro', isa => 'Str');
}
1;
