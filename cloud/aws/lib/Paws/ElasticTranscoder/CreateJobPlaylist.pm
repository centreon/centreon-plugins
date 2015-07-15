package Paws::ElasticTranscoder::CreateJobPlaylist {
  use Moose;
  has Format => (is => 'ro', isa => 'Str');
  has HlsContentProtection => (is => 'ro', isa => 'Paws::ElasticTranscoder::HlsContentProtection');
  has Name => (is => 'ro', isa => 'Str');
  has OutputKeys => (is => 'ro', isa => 'ArrayRef[Str]');
  has PlayReadyDrm => (is => 'ro', isa => 'Paws::ElasticTranscoder::PlayReadyDrm');
}
1;
