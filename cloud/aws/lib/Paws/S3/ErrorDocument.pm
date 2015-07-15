package Paws::S3::ErrorDocument {
  use Moose;
  has Key => (is => 'ro', isa => 'Str', required => 1);
}
1;
