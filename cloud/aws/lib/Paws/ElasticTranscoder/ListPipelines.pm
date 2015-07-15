
package Paws::ElasticTranscoder::ListPipelines {
  use Moose;
  has Ascending => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'Ascending' );
  has PageToken => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'PageToken' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListPipelines');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2012-09-25/pipelines');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticTranscoder::ListPipelinesResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListPipelinesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticTranscoder::ListPipelines - Arguments for method ListPipelines on Paws::ElasticTranscoder

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListPipelines on the 
Amazon Elastic Transcoder service. Use the attributes of this class
as arguments to method ListPipelines.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListPipelines.

As an example:

  $service_obj->ListPipelines(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Ascending => Str

  

To list pipelines in chronological order by the date and time that they
were created, enter C<true>. To list pipelines in reverse chronological
order, enter C<false>.










=head2 PageToken => Str

  

When Elastic Transcoder returns more than one page of results, use
C<pageToken> in subsequent C<GET> requests to get each successive page
of results.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListPipelines in L<Paws::ElasticTranscoder>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

