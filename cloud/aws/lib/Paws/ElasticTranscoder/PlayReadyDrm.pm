package Paws::ElasticTranscoder::PlayReadyDrm {
  use Moose;
  has Format => (is => 'ro', isa => 'Str');
  has InitializationVector => (is => 'ro', isa => 'Str');
  has Key => (is => 'ro', isa => 'Str');
  has KeyId => (is => 'ro', isa => 'Str');
  has KeyMd5 => (is => 'ro', isa => 'Str');
  has LicenseAcquisitionUrl => (is => 'ro', isa => 'Str');
}
1;
