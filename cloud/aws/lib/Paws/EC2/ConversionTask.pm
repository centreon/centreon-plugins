package Paws::EC2::ConversionTask {
  use Moose;
  has ConversionTaskId => (is => 'ro', isa => 'Str', xmlname => 'conversionTaskId', traits => ['Unwrapped'], required => 1);
  has ExpirationTime => (is => 'ro', isa => 'Str', xmlname => 'expirationTime', traits => ['Unwrapped']);
  has ImportInstance => (is => 'ro', isa => 'Paws::EC2::ImportInstanceTaskDetails', xmlname => 'importInstance', traits => ['Unwrapped']);
  has ImportVolume => (is => 'ro', isa => 'Paws::EC2::ImportVolumeTaskDetails', xmlname => 'importVolume', traits => ['Unwrapped']);
  has State => (is => 'ro', isa => 'Str', xmlname => 'state', traits => ['Unwrapped'], required => 1);
  has StatusMessage => (is => 'ro', isa => 'Str', xmlname => 'statusMessage', traits => ['Unwrapped']);
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Tag]', xmlname => 'tagSet', traits => ['Unwrapped']);
}
1;
