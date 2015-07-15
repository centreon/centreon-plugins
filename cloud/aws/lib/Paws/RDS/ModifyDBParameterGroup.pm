
package Paws::RDS::ModifyDBParameterGroup {
  use Moose;
  has DBParameterGroupName => (is => 'ro', isa => 'Str', required => 1);
  has Parameters => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Parameter]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyDBParameterGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::DBParameterGroupNameMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ModifyDBParameterGroupResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::ModifyDBParameterGroup - Arguments for method ModifyDBParameterGroup on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyDBParameterGroup on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method ModifyDBParameterGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyDBParameterGroup.

As an example:

  $service_obj->ModifyDBParameterGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DBParameterGroupName => Str

  

The name of the DB parameter group.

Constraints:

=over

=item * Must be the name of an existing DB parameter group

=item * Must be 1 to 255 alphanumeric characters

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back










=head2 B<REQUIRED> Parameters => ArrayRef[Paws::RDS::Parameter]

  

An array of parameter names, values, and the apply method for the
parameter update. At least one parameter name, value, and apply method
must be supplied; subsequent arguments are optional. A maximum of 20
parameters may be modified in a single request.

Valid Values (for the application method): C<immediate |
pending-reboot>

You can use the immediate value with dynamic parameters only. You can
use the pending-reboot value for both dynamic and static parameters,
and changes are applied when you reboot the DB instance without
failover.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyDBParameterGroup in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

