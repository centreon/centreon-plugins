
package Paws::SDB::BatchDeleteAttributes {
  use Moose;
  has DomainName => (is => 'ro', isa => 'Str', required => 1);
  has Items => (is => 'ro', isa => 'ArrayRef[Paws::SDB::DeletableItem]', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'BatchDeleteAttributes');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SDB::BatchDeleteAttributes - Arguments for method BatchDeleteAttributes on Paws::SDB

=head1 DESCRIPTION

This class represents the parameters used for calling the method BatchDeleteAttributes on the 
Amazon SimpleDB service. Use the attributes of this class
as arguments to method BatchDeleteAttributes.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to BatchDeleteAttributes.

As an example:

  $service_obj->BatchDeleteAttributes(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DomainName => Str

  

The name of the domain in which the attributes are being deleted.










=head2 B<REQUIRED> Items => ArrayRef[Paws::SDB::DeletableItem]

  

A list of items on which to perform the operation.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method BatchDeleteAttributes in L<Paws::SDB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

