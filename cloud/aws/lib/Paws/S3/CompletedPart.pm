package Paws::S3::CompletedPart {
  use Moose;
  has ETag => (is => 'ro', isa => 'Str');
  has PartNumber => (is => 'ro', isa => 'Int');
}
1;
