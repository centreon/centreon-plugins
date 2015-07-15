package Paws::ElasticTranscoder::Timing {
  use Moose;
  has FinishTimeMillis => (is => 'ro', isa => 'Int');
  has StartTimeMillis => (is => 'ro', isa => 'Int');
  has SubmitTimeMillis => (is => 'ro', isa => 'Int');
}
1;
