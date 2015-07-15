package Paws::S3::Tagging {
  use Moose;
  has TagSet => (is => 'ro', isa => 'ArrayRef[Paws::S3::Tag]', required => 1);
}
1;
