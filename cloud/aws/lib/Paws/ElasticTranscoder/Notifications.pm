package Paws::ElasticTranscoder::Notifications {
  use Moose;
  has Completed => (is => 'ro', isa => 'Str');
  has Error => (is => 'ro', isa => 'Str');
  has Progressing => (is => 'ro', isa => 'Str');
  has Warning => (is => 'ro', isa => 'Str');
}
1;
