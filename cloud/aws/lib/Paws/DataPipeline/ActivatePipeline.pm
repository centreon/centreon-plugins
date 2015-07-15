
package Paws::DataPipeline::ActivatePipeline {
  use Moose;
  has parameterValues => (is => 'ro', isa => 'ArrayRef[Paws::DataPipeline::ParameterValue]');
  has pipelineId => (is => 'ro', isa => 'Str', required => 1);
  has startTimestamp => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ActivatePipeline');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DataPipeline::ActivatePipelineOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::ActivatePipeline - Arguments for method ActivatePipeline on Paws::DataPipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method ActivatePipeline on the 
AWS Data Pipeline service. Use the attributes of this class
as arguments to method ActivatePipeline.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ActivatePipeline.

As an example:

  $service_obj->ActivatePipeline(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 parameterValues => ArrayRef[Paws::DataPipeline::ParameterValue]

  

A list of parameter values to pass to the pipeline at activation.










=head2 B<REQUIRED> pipelineId => Str

  

The ID of the pipeline.










=head2 startTimestamp => Str

  

The date and time to resume the pipeline. By default, the pipeline
resumes from the last completed execution.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ActivatePipeline in L<Paws::DataPipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

