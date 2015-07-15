
package Paws::ElasticTranscoder::ListJobsByPipeline {
  use Moose;
  has Ascending => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'Ascending' );
  has PageToken => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'PageToken' );
  has PipelineId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'PipelineId' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListJobsByPipeline');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2012-09-25/jobsByPipeline/{PipelineId}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticTranscoder::ListJobsByPipelineResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListJobsByPipelineResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticTranscoder::ListJobsByPipeline - Arguments for method ListJobsByPipeline on Paws::ElasticTranscoder

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListJobsByPipeline on the 
Amazon Elastic Transcoder service. Use the attributes of this class
as arguments to method ListJobsByPipeline.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListJobsByPipeline.

As an example:

  $service_obj->ListJobsByPipeline(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Ascending => Str

  

To list jobs in chronological order by the date and time that they were
submitted, enter C<true>. To list jobs in reverse chronological order,
enter C<false>.










=head2 PageToken => Str

  

When Elastic Transcoder returns more than one page of results, use
C<pageToken> in subsequent C<GET> requests to get each successive page
of results.










=head2 B<REQUIRED> PipelineId => Str

  

The ID of the pipeline for which you want to get job information.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListJobsByPipeline in L<Paws::ElasticTranscoder>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

