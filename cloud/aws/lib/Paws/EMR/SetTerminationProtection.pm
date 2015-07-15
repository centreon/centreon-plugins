
package Paws::EMR::SetTerminationProtection {
  use Moose;
  has JobFlowIds => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has TerminationProtected => (is => 'ro', isa => 'Bool', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SetTerminationProtection');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EMR::SetTerminationProtection - Arguments for method SetTerminationProtection on Paws::EMR

=head1 DESCRIPTION

This class represents the parameters used for calling the method SetTerminationProtection on the 
Amazon Elastic MapReduce service. Use the attributes of this class
as arguments to method SetTerminationProtection.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SetTerminationProtection.

As an example:

  $service_obj->SetTerminationProtection(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> JobFlowIds => ArrayRef[Str]

  

A list of strings that uniquely identify the job flows to protect. This
identifier is returned by RunJobFlow and can also be obtained from
DescribeJobFlows .










=head2 B<REQUIRED> TerminationProtected => Bool

  

A Boolean that indicates whether to protect the job flow and prevent
the Amazon EC2 instances in the cluster from shutting down due to API
calls, user intervention, or job-flow error.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SetTerminationProtection in L<Paws::EMR>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

