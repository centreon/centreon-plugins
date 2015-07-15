
package Paws::RedShift::ResetClusterParameterGroup {
  use Moose;
  has ParameterGroupName => (is => 'ro', isa => 'Str', required => 1);
  has Parameters => (is => 'ro', isa => 'ArrayRef[Paws::RedShift::Parameter]');
  has ResetAllParameters => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ResetClusterParameterGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::ClusterParameterGroupNameMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ResetClusterParameterGroupResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::ResetClusterParameterGroup - Arguments for method ResetClusterParameterGroup on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method ResetClusterParameterGroup on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method ResetClusterParameterGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ResetClusterParameterGroup.

As an example:

  $service_obj->ResetClusterParameterGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ParameterGroupName => Str

  

The name of the cluster parameter group to be reset.










=head2 Parameters => ArrayRef[Paws::RedShift::Parameter]

  

An array of names of parameters to be reset. If I<ResetAllParameters>
option is not used, then at least one parameter name must be supplied.

Constraints: A maximum of 20 parameters can be reset in a single
request.










=head2 ResetAllParameters => Bool

  

If C<true>, all parameters in the specified parameter group will be
reset to their default values.

Default: C<true>












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ResetClusterParameterGroup in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

