
package Paws::DataPipeline::DeactivatePipeline {
  use Moose;
  has cancelActive => (is => 'ro', isa => 'Bool');
  has pipelineId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeactivatePipeline');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DataPipeline::DeactivatePipelineOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::DeactivatePipeline - Arguments for method DeactivatePipeline on Paws::DataPipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeactivatePipeline on the 
AWS Data Pipeline service. Use the attributes of this class
as arguments to method DeactivatePipeline.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeactivatePipeline.

As an example:

  $service_obj->DeactivatePipeline(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 cancelActive => Bool

  

Indicates whether to cancel any running objects. The default is true,
which sets the state of any running objects to C<CANCELED>. If this
value is false, the pipeline is deactivated after all running objects
finish.










=head2 B<REQUIRED> pipelineId => Str

  

The ID of the pipeline.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeactivatePipeline in L<Paws::DataPipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

