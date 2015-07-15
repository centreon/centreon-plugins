
package Paws::ElasticTranscoder::CreatePreset {
  use Moose;
  has Audio => (is => 'ro', isa => 'Paws::ElasticTranscoder::AudioParameters');
  has Container => (is => 'ro', isa => 'Str', required => 1);
  has Description => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str', required => 1);
  has Thumbnails => (is => 'ro', isa => 'Paws::ElasticTranscoder::Thumbnails');
  has Video => (is => 'ro', isa => 'Paws::ElasticTranscoder::VideoParameters');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreatePreset');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2012-09-25/presets');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticTranscoder::CreatePresetResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreatePresetResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticTranscoder::CreatePreset - Arguments for method CreatePreset on Paws::ElasticTranscoder

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreatePreset on the 
Amazon Elastic Transcoder service. Use the attributes of this class
as arguments to method CreatePreset.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreatePreset.

As an example:

  $service_obj->CreatePreset(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Audio => Paws::ElasticTranscoder::AudioParameters

  

A section of the request body that specifies the audio parameters.










=head2 B<REQUIRED> Container => Str

  

The container type for the output file. Valid values include C<flac>,
C<flv>, C<fmp4>, C<gif>, C<mp3>, C<mp4>, C<mpg>, C<mxf>, C<oga>,
C<ogg>, C<ts>, and C<webm>.










=head2 Description => Str

  

A description of the preset.










=head2 B<REQUIRED> Name => Str

  

The name of the preset. We recommend that the name be unique within the
AWS account, but uniqueness is not enforced.










=head2 Thumbnails => Paws::ElasticTranscoder::Thumbnails

  

A section of the request body that specifies the thumbnail parameters,
if any.










=head2 Video => Paws::ElasticTranscoder::VideoParameters

  

A section of the request body that specifies the video parameters.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreatePreset in L<Paws::ElasticTranscoder>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

