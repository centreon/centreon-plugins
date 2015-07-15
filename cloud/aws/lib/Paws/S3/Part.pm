package Paws::S3::Part {
  use Moose;
  has ETag => (is => 'ro', isa => 'Str');
  has LastModified => (is => 'ro', isa => 'Str');
  has PartNumber => (is => 'ro', isa => 'Int');
  has Size => (is => 'ro', isa => 'Int');
}
1;
