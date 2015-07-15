
package Paws::DynamoDB::BatchGetItem {
  use Moose;
  has RequestItems => (is => 'ro', isa => 'Paws::DynamoDB::BatchGetRequestMap', required => 1);
  has ReturnConsumedCapacity => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'BatchGetItem');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DynamoDB::BatchGetItemOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDB::BatchGetItem - Arguments for method BatchGetItem on Paws::DynamoDB

=head1 DESCRIPTION

This class represents the parameters used for calling the method BatchGetItem on the 
Amazon DynamoDB service. Use the attributes of this class
as arguments to method BatchGetItem.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to BatchGetItem.

As an example:

  $service_obj->BatchGetItem(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> RequestItems => Paws::DynamoDB::BatchGetRequestMap

  

A map of one or more table names and, for each table, a map that
describes one or more items to retrieve from that table. Each table
name can be used only once per I<BatchGetItem> request.

Each element in the map of items to retrieve consists of the following:

=over

=item *

I<ConsistentRead> - If C<true>, a strongly consistent read is used; if
C<false> (the default), an eventually consistent read is used.

=item *

I<ExpressionAttributeNames> - One or more substitution tokens for
attribute names in the I<ProjectionExpression> parameter. The following
are some use cases for using I<ExpressionAttributeNames>:

=over

=item *

To access an attribute whose name conflicts with a DynamoDB reserved
word.

=item *

To create a placeholder for repeating occurrences of an attribute name
in an expression.

=item *

To prevent special characters in an attribute name from being
misinterpreted in an expression.

=back

Use the B<
name. For example, consider the following attribute name:

=over

=item *

C<Percentile>

=back

The name of this attribute conflicts with a reserved word, so it cannot
be used directly in an expression. (For the complete list of reserved
words, see Reserved Words in the I<Amazon DynamoDB Developer Guide>).
To work around this, you could specify the following for
I<ExpressionAttributeNames>:

=over

=item *

C<{"

=back

You could then use this substitution in an expression, as in this
example:

=over

=item *

C<

=back

Tokens that begin with the B<:> character are I<expression attribute
values>, which are placeholders for the actual value at runtime.

For more information on expression attribute names, see Accessing Item
Attributes in the I<Amazon DynamoDB Developer Guide>.

=item *

I<Keys> - An array of primary key attribute values that define specific
items in the table. For each primary key, you must provide I<all> of
the key attributes. For example, with a hash type primary key, you only
need to provide the hash attribute. For a hash-and-range type primary
key, you must provide I<both> the hash attribute and the range
attribute.

=item *

I<ProjectionExpression> - A string that identifies one or more
attributes to retrieve from the table. These attributes can include
scalars, sets, or elements of a JSON document. The attributes in the
expression must be separated by commas.

If no attribute names are specified, then all attributes will be
returned. If any of the requested attributes are not found, they will
not appear in the result.

For more information, see Accessing Item Attributes in the I<Amazon
DynamoDB Developer Guide>.

=item *

I<AttributesToGet> -

This is a legacy parameter, for backward compatibility. New
applications should use I<ProjectionExpression> instead. Do not combine
legacy parameters and expression parameters in a single API call;
otherwise, DynamoDB will return a I<ValidationException> exception.

This parameter allows you to retrieve attributes of type List or Map;
however, it cannot retrieve individual elements within a List or a Map.

The names of one or more attributes to retrieve. If no attribute names
are provided, then all attributes will be returned. If any of the
requested attributes are not found, they will not appear in the result.

Note that I<AttributesToGet> has no effect on provisioned throughput
consumption. DynamoDB determines capacity units consumed based on item
size, not on the amount of data that is returned to an application.

=back










=head2 ReturnConsumedCapacity => Str

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method BatchGetItem in L<Paws::DynamoDB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

