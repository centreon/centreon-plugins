package Paws::ElasticTranscoder::Playlist {
  use Moose;
  has Format => (is => 'ro', isa => 'Str');
  has HlsContentProtection => (is => 'ro', isa => 'Paws::ElasticTranscoder::HlsContentProtection');
  has Name => (is => 'ro', isa => 'Str');
  has OutputKeys => (is => 'ro', isa => 'ArrayRef[Str]');
  has PlayReadyDrm => (is => 'ro', isa => 'Paws::ElasticTranscoder::PlayReadyDrm');
  has Status => (is => 'ro', isa => 'Str');
  has StatusDetail => (is => 'ro', isa => 'Str');
}
1;
