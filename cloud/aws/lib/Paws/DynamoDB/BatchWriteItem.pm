
package Paws::DynamoDB::BatchWriteItem {
  use Moose;
  has RequestItems => (is => 'ro', isa => 'Paws::DynamoDB::BatchWriteItemRequestMap', required => 1);
  has ReturnConsumedCapacity => (is => 'ro', isa => 'Str');
  has ReturnItemCollectionMetrics => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'BatchWriteItem');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DynamoDB::BatchWriteItemOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDB::BatchWriteItem - Arguments for method BatchWriteItem on Paws::DynamoDB

=head1 DESCRIPTION

This class represents the parameters used for calling the method BatchWriteItem on the 
Amazon DynamoDB service. Use the attributes of this class
as arguments to method BatchWriteItem.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to BatchWriteItem.

As an example:

  $service_obj->BatchWriteItem(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> RequestItems => Paws::DynamoDB::BatchWriteItemRequestMap

  

A map of one or more table names and, for each table, a list of
operations to be performed (I<DeleteRequest> or I<PutRequest>). Each
element in the map consists of the following:

=over

=item *

I<DeleteRequest> - Perform a I<DeleteItem> operation on the specified
item. The item to be deleted is identified by a I<Key> subelement:

=over

=item *

I<Key> - A map of primary key attribute values that uniquely identify
the ! item. Each entry in this map consists of an attribute name and an
attribute value. For each primary key, you must provide I<all> of the
key attributes. For example, with a hash type primary key, you only
need to provide the hash attribute. For a hash-and-range type primary
key, you must provide I<both> the hash attribute and the range
attribute.

=back

=item *

I<PutRequest> - Perform a I<PutItem> operation on the specified item.
The item to be put is identified by an I<Item> subelement:

=over

=item *

I<Item> - A map of attributes and their values. Each entry in this map
consists of an attribute name and an attribute value. Attribute values
must not be null; string and binary type attributes must have lengths
greater than zero; and set type attributes must not be empty. Requests
that contain empty values will be rejected with a
I<ValidationException> exception.

If you specify any attributes that are part of an index key, then the
data types for those attributes must match those of the schema in the
table's attribute definition.

=back

=back










=head2 ReturnConsumedCapacity => Str

  

=head2 ReturnItemCollectionMetrics => Str

  

A value that if set to C<SIZE>, the response includes statistics about
item collections, if any, that were modified during the operation are
returned in the response. If set to C<NONE> (the default), no
statistics are returned.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method BatchWriteItem in L<Paws::DynamoDB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

