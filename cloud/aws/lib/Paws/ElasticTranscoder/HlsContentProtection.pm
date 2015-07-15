package Paws::ElasticTranscoder::HlsContentProtection {
  use Moose;
  has InitializationVector => (is => 'ro', isa => 'Str');
  has Key => (is => 'ro', isa => 'Str');
  has KeyMd5 => (is => 'ro', isa => 'Str');
  has KeyStoragePolicy => (is => 'ro', isa => 'Str');
  has LicenseAcquisitionUrl => (is => 'ro', isa => 'Str');
  has Method => (is => 'ro', isa => 'Str');
}
1;
