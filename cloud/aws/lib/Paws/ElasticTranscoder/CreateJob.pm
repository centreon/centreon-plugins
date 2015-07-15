
package Paws::ElasticTranscoder::CreateJob {
  use Moose;
  has Input => (is => 'ro', isa => 'Paws::ElasticTranscoder::JobInput', required => 1);
  has Output => (is => 'ro', isa => 'Paws::ElasticTranscoder::CreateJobOutput');
  has OutputKeyPrefix => (is => 'ro', isa => 'Str');
  has Outputs => (is => 'ro', isa => 'ArrayRef[Paws::ElasticTranscoder::CreateJobOutput]');
  has PipelineId => (is => 'ro', isa => 'Str', required => 1);
  has Playlists => (is => 'ro', isa => 'ArrayRef[Paws::ElasticTranscoder::CreateJobPlaylist]');
  has UserMetadata => (is => 'ro', isa => 'Paws::ElasticTranscoder::UserMetadata');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateJob');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2012-09-25/jobs');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticTranscoder::CreateJobResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateJobResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticTranscoder::CreateJob - Arguments for method CreateJob on Paws::ElasticTranscoder

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateJob on the 
Amazon Elastic Transcoder service. Use the attributes of this class
as arguments to method CreateJob.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateJob.

As an example:

  $service_obj->CreateJob(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Input => Paws::ElasticTranscoder::JobInput

  

A section of the request body that provides information about the file
that is being transcoded.










=head2 Output => Paws::ElasticTranscoder::CreateJobOutput

  

=head2 OutputKeyPrefix => Str

  

The value, if any, that you want Elastic Transcoder to prepend to the
names of all files that this job creates, including output files,
thumbnails, and playlists.










=head2 Outputs => ArrayRef[Paws::ElasticTranscoder::CreateJobOutput]

  

A section of the request body that provides information about the
transcoded (target) files. We recommend that you use the C<Outputs>
syntax instead of the C<Output> syntax.










=head2 B<REQUIRED> PipelineId => Str

  

The C<Id> of the pipeline that you want Elastic Transcoder to use for
transcoding. The pipeline determines several settings, including the
Amazon S3 bucket from which Elastic Transcoder gets the files to
transcode and the bucket into which Elastic Transcoder puts the
transcoded files.










=head2 Playlists => ArrayRef[Paws::ElasticTranscoder::CreateJobPlaylist]

  

If you specify a preset in C<PresetId> for which the value of
C<Container> is fmp4 (Fragmented MP4) or ts (MPEG-TS), Playlists
contains information about the master playlists that you want Elastic
Transcoder to create.

The maximum number of master playlists in a job is 30.










=head2 UserMetadata => Paws::ElasticTranscoder::UserMetadata

  

User-defined metadata that you want to associate with an Elastic
Transcoder job. You specify metadata in C<key/value> pairs, and you can
add up to 10 C<key/value> pairs per job. Elastic Transcoder does not
guarantee that C<key/value> pairs will be returned in the same order in
which you specify them.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateJob in L<Paws::ElasticTranscoder>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

