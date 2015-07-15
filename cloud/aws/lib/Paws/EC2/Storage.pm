package Paws::EC2::Storage {
  use Moose;
  has S3 => (is => 'ro', isa => 'Paws::EC2::S3Storage');
}
1;
