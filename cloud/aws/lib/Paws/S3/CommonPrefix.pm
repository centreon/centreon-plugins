package Paws::S3::CommonPrefix {
  use Moose;
  has Prefix => (is => 'ro', isa => 'Str');
}
1;
