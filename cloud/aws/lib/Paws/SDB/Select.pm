
package Paws::SDB::Select {
  use Moose;
  has ConsistentRead => (is => 'ro', isa => 'Bool');
  has NextToken => (is => 'ro', isa => 'Str');
  has SelectExpression => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'Select');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SDB::SelectResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'SelectResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SDB::Select - Arguments for method Select on Paws::SDB

=head1 DESCRIPTION

This class represents the parameters used for calling the method Select on the 
Amazon SimpleDB service. Use the attributes of this class
as arguments to method Select.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to Select.

As an example:

  $service_obj->Select(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ConsistentRead => Bool

  

Determines whether or not strong consistency should be enforced when
data is read from SimpleDB. If C<true>, any data previously written to
SimpleDB will be returned. Otherwise, results will be consistent
eventually, and the client may not see data that was written
immediately before your read.










=head2 NextToken => Str

  

A string informing Amazon SimpleDB where to start the next list of
C<ItemNames>.










=head2 B<REQUIRED> SelectExpression => Str

  

The expression used to query the domain.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method Select in L<Paws::SDB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

