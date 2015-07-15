package Paws::StorageGateway::Tape {
  use Moose;
  has Progress => (is => 'ro', isa => 'Num');
  has TapeARN => (is => 'ro', isa => 'Str');
  has TapeBarcode => (is => 'ro', isa => 'Str');
  has TapeSizeInBytes => (is => 'ro', isa => 'Int');
  has TapeStatus => (is => 'ro', isa => 'Str');
  has VTLDevice => (is => 'ro', isa => 'Str');
}
1;
