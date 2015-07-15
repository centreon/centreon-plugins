package Paws::ElasticTranscoder::TimeSpan {
  use Moose;
  has Duration => (is => 'ro', isa => 'Str');
  has StartTime => (is => 'ro', isa => 'Str');
}
1;
