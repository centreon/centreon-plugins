
package Paws::EMR::AddJobFlowSteps {
  use Moose;
  has JobFlowId => (is => 'ro', isa => 'Str', required => 1);
  has Steps => (is => 'ro', isa => 'ArrayRef[Paws::EMR::StepConfig]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AddJobFlowSteps');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EMR::AddJobFlowStepsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EMR::AddJobFlowSteps - Arguments for method AddJobFlowSteps on Paws::EMR

=head1 DESCRIPTION

This class represents the parameters used for calling the method AddJobFlowSteps on the 
Amazon Elastic MapReduce service. Use the attributes of this class
as arguments to method AddJobFlowSteps.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AddJobFlowSteps.

As an example:

  $service_obj->AddJobFlowSteps(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> JobFlowId => Str

  

A string that uniquely identifies the job flow. This identifier is
returned by RunJobFlow and can also be obtained from ListClusters.










=head2 B<REQUIRED> Steps => ArrayRef[Paws::EMR::StepConfig]

  

A list of StepConfig to be executed by the job flow.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AddJobFlowSteps in L<Paws::EMR>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

