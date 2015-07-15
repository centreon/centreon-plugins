
package Paws::ElasticTranscoder::CreatePresetResponse {
  use Moose;
  has Preset => (is => 'ro', isa => 'Paws::ElasticTranscoder::Preset');
  has Warning => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticTranscoder::CreatePresetResponse

=head1 ATTRIBUTES

=head2 Preset => Paws::ElasticTranscoder::Preset

  

A section of the response body that provides information about the
preset that is created.









=head2 Warning => Str

  

If the preset settings don't comply with the standards for the video
codec but Elastic Transcoder created the preset, this message explains
the reason the preset settings don't meet the standard. Elastic
Transcoder created the preset because the settings might produce
acceptable output.











=cut

