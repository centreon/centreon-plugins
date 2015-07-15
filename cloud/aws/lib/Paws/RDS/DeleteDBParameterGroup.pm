
package Paws::RDS::DeleteDBParameterGroup {
  use Moose;
  has DBParameterGroupName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteDBParameterGroup');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::DeleteDBParameterGroup - Arguments for method DeleteDBParameterGroup on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteDBParameterGroup on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method DeleteDBParameterGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteDBParameterGroup.

As an example:

  $service_obj->DeleteDBParameterGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DBParameterGroupName => Str

  

The name of the DB parameter group.

Constraints:

=over

=item * Must be the name of an existing DB parameter group

=item * You cannot delete a default DB parameter group

=item * Cannot be associated with any DB instances

=back












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteDBParameterGroup in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

