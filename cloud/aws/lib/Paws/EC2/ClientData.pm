package Paws::EC2::ClientData {
  use Moose;
  has Comment => (is => 'ro', isa => 'Str');
  has UploadEnd => (is => 'ro', isa => 'Str');
  has UploadSize => (is => 'ro', isa => 'Num');
  has UploadStart => (is => 'ro', isa => 'Str');
}
1;
