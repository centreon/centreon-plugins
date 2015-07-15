package Paws::ElasticTranscoder::Warning {
  use Moose;
  has Code => (is => 'ro', isa => 'Str');
  has Message => (is => 'ro', isa => 'Str');
}
1;
