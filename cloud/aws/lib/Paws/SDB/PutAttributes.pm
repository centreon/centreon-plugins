
package Paws::SDB::PutAttributes {
  use Moose;
  has Attributes => (is => 'ro', isa => 'ArrayRef[Paws::SDB::ReplaceableAttribute]', required => 1);
  has DomainName => (is => 'ro', isa => 'Str', required => 1);
  has Expected => (is => 'ro', isa => 'Paws::SDB::UpdateCondition');
  has ItemName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutAttributes');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SDB::PutAttributes - Arguments for method PutAttributes on Paws::SDB

=head1 DESCRIPTION

This class represents the parameters used for calling the method PutAttributes on the 
Amazon SimpleDB service. Use the attributes of this class
as arguments to method PutAttributes.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PutAttributes.

As an example:

  $service_obj->PutAttributes(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Attributes => ArrayRef[Paws::SDB::ReplaceableAttribute]

  

The list of attributes.










=head2 B<REQUIRED> DomainName => Str

  

The name of the domain in which to perform the operation.










=head2 Expected => Paws::SDB::UpdateCondition

  

The update condition which, if specified, determines whether the
specified attributes will be updated or not. The update condition must
be satisfied in order for this request to be processed and the
attributes to be updated.










=head2 B<REQUIRED> ItemName => Str

  

The name of the item.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutAttributes in L<Paws::SDB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

