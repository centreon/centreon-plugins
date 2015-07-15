
package Paws::SDB::GetAttributes {
  use Moose;
  has AttributeNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has ConsistentRead => (is => 'ro', isa => 'Bool');
  has DomainName => (is => 'ro', isa => 'Str', required => 1);
  has ItemName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetAttributes');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SDB::GetAttributesResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'GetAttributesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SDB::GetAttributes - Arguments for method GetAttributes on Paws::SDB

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetAttributes on the 
Amazon SimpleDB service. Use the attributes of this class
as arguments to method GetAttributes.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetAttributes.

As an example:

  $service_obj->GetAttributes(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AttributeNames => ArrayRef[Str]

  

The names of the attributes.










=head2 ConsistentRead => Bool

  

Determines whether or not strong consistency should be enforced when
data is read from SimpleDB. If C<true>, any data previously written to
SimpleDB will be returned. Otherwise, results will be consistent
eventually, and the client may not see data that was written
immediately before your read.










=head2 B<REQUIRED> DomainName => Str

  

The name of the domain in which to perform the operation.










=head2 B<REQUIRED> ItemName => Str

  

The name of the item.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetAttributes in L<Paws::SDB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

