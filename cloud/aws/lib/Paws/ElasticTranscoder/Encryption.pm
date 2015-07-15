package Paws::ElasticTranscoder::Encryption {
  use Moose;
  has InitializationVector => (is => 'ro', isa => 'Str');
  has Key => (is => 'ro', isa => 'Str');
  has KeyMd5 => (is => 'ro', isa => 'Str');
  has Mode => (is => 'ro', isa => 'Str');
}
1;
