
package Paws::EMR::AddInstanceGroups {
  use Moose;
  has InstanceGroups => (is => 'ro', isa => 'ArrayRef[Paws::EMR::InstanceGroupConfig]', required => 1);
  has JobFlowId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AddInstanceGroups');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EMR::AddInstanceGroupsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EMR::AddInstanceGroups - Arguments for method AddInstanceGroups on Paws::EMR

=head1 DESCRIPTION

This class represents the parameters used for calling the method AddInstanceGroups on the 
Amazon Elastic MapReduce service. Use the attributes of this class
as arguments to method AddInstanceGroups.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AddInstanceGroups.

As an example:

  $service_obj->AddInstanceGroups(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> InstanceGroups => ArrayRef[Paws::EMR::InstanceGroupConfig]

  

Instance Groups to add.










=head2 B<REQUIRED> JobFlowId => Str

  

Job flow in which to add the instance groups.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AddInstanceGroups in L<Paws::EMR>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

