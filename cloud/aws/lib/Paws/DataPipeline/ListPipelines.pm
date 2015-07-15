
package Paws::DataPipeline::ListPipelines {
  use Moose;
  has marker => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListPipelines');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DataPipeline::ListPipelinesOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::ListPipelines - Arguments for method ListPipelines on Paws::DataPipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListPipelines on the 
AWS Data Pipeline service. Use the attributes of this class
as arguments to method ListPipelines.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListPipelines.

As an example:

  $service_obj->ListPipelines(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 marker => Str

  

The starting point for the results to be returned. For the first call,
this value should be empty. As long as there are more results, continue
to call C<ListPipelines> with the marker value from the previous call
to retrieve the next set of results.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListPipelines in L<Paws::DataPipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

