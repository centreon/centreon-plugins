
package Paws::RDS::RebootDBInstance {
  use Moose;
  has DBInstanceIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has ForceFailover => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RebootDBInstance');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::RebootDBInstanceResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'RebootDBInstanceResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::RebootDBInstance - Arguments for method RebootDBInstance on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method RebootDBInstance on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method RebootDBInstance.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RebootDBInstance.

As an example:

  $service_obj->RebootDBInstance(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DBInstanceIdentifier => Str

  

The DB instance identifier. This parameter is stored as a lowercase
string.

Constraints:

=over

=item * Must contain from 1 to 63 alphanumeric characters or hyphens

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back










=head2 ForceFailover => Bool

  

When C<true>, the reboot will be conducted through a MultiAZ failover.

Constraint: You cannot specify C<true> if the instance is not
configured for MultiAZ.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RebootDBInstance in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

