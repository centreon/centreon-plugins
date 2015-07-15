
package Paws::DataPipeline::DescribePipelines {
  use Moose;
  has pipelineIds => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribePipelines');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DataPipeline::DescribePipelinesOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::DescribePipelines - Arguments for method DescribePipelines on Paws::DataPipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribePipelines on the 
AWS Data Pipeline service. Use the attributes of this class
as arguments to method DescribePipelines.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribePipelines.

As an example:

  $service_obj->DescribePipelines(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> pipelineIds => ArrayRef[Str]

  

The IDs of the pipelines to describe. You can pass as many as 25
identifiers in a single call. To obtain pipeline IDs, call
ListPipelines.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribePipelines in L<Paws::DataPipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

