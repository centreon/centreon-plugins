package Paws::ElasticTranscoder::Clip {
  use Moose;
  has TimeSpan => (is => 'ro', isa => 'Paws::ElasticTranscoder::TimeSpan');
}
1;
