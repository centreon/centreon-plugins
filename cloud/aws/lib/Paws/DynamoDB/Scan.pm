
package Paws::DynamoDB::Scan {
  use Moose;
  has AttributesToGet => (is => 'ro', isa => 'ArrayRef[Str]');
  has ConditionalOperator => (is => 'ro', isa => 'Str');
  has ExclusiveStartKey => (is => 'ro', isa => 'Paws::DynamoDB::Key');
  has ExpressionAttributeNames => (is => 'ro', isa => 'Paws::DynamoDB::ExpressionAttributeNameMap');
  has ExpressionAttributeValues => (is => 'ro', isa => 'Paws::DynamoDB::ExpressionAttributeValueMap');
  has FilterExpression => (is => 'ro', isa => 'Str');
  has IndexName => (is => 'ro', isa => 'Str');
  has Limit => (is => 'ro', isa => 'Int');
  has ProjectionExpression => (is => 'ro', isa => 'Str');
  has ReturnConsumedCapacity => (is => 'ro', isa => 'Str');
  has ScanFilter => (is => 'ro', isa => 'Paws::DynamoDB::FilterConditionMap');
  has Segment => (is => 'ro', isa => 'Int');
  has Select => (is => 'ro', isa => 'Str');
  has TableName => (is => 'ro', isa => 'Str', required => 1);
  has TotalSegments => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'Scan');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DynamoDB::ScanOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDB::Scan - Arguments for method Scan on Paws::DynamoDB

=head1 DESCRIPTION

This class represents the parameters used for calling the method Scan on the 
Amazon DynamoDB service. Use the attributes of this class
as arguments to method Scan.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to Scan.

As an example:

  $service_obj->Scan(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AttributesToGet => ArrayRef[Str]

  

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










=head2 ConditionalOperator => Str

  

This is a legacy parameter, for backward compatibility. New
applications should use I<FilterExpression> instead. Do not combine
legacy parameters and expression parameters in a single API call;
otherwise, DynamoDB will return a I<ValidationException> exception.

A logical operator to apply to the conditions in a I<ScanFilter> map:

=over

=item *

C<AND> - If all of the conditions evaluate to true, then the entire map
evaluates to true.

=item *

C<OR> - If at least one of the conditions evaluate to true, then the
entire map evaluates to true.

=back

If you omit I<ConditionalOperator>, then C<AND> is the default.

The operation will succeed only if the entire map evaluates to true.

This parameter does not support attributes of type List or Map.










=head2 ExclusiveStartKey => Paws::DynamoDB::Key

  

The primary key of the first item that this operation will evaluate.
Use the value that was returned for I<LastEvaluatedKey> in the previous
operation.

The data type for I<ExclusiveStartKey> must be String, Number or
Binary. No set data types are allowed.

In a parallel scan, a I<Scan> request that includes
I<ExclusiveStartKey> must specify the same segment whose previous
I<Scan> returned the corresponding value of I<LastEvaluatedKey>.










=head2 ExpressionAttributeNames => Paws::DynamoDB::ExpressionAttributeNameMap

  

One or more substitution tokens for attribute names in an expression.
The following are some use cases for using I<ExpressionAttributeNames>:

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

For more information on expression attribute names, see Using
Placeholders for Attribute Names and Values in the I<Amazon DynamoDB
Developer Guide>.










=head2 ExpressionAttributeValues => Paws::DynamoDB::ExpressionAttributeValueMap

  

One or more values that can be substituted in an expression.

Use the B<:> (colon) character in an expression to dereference an
attribute value. For example, suppose that you wanted to check whether
the value of the I<ProductStatus> attribute was one of the following:

C<Available | Backordered | Discontinued>

You would first need to specify I<ExpressionAttributeValues> as
follows:

C<{ ":avail":{"S":"Available"}, ":back":{"S":"Backordered"},
":disc":{"S":"Discontinued"} }>

You could then use these values in an expression, such as this:

C<ProductStatus IN (:avail, :back, :disc)>

For more information on expression attribute values, see Using
Placeholders for Attribute Names and Values in the I<Amazon DynamoDB
Developer Guide>.










=head2 FilterExpression => Str

  

A string that contains conditions that DynamoDB applies after the
I<Scan> operation, but before the data is returned to you. Items that
do not satisfy the I<FilterExpression> criteria are not returned.

A I<FilterExpression> is applied after the items have already been
read; the process of filtering does not consume any additional read
capacity units.

For more information, see Filter Expressions in the I<Amazon DynamoDB
Developer Guide>.

I<FilterExpression> replaces the legacy I<ScanFilter> and
I<ConditionalOperator> parameters.










=head2 IndexName => Str

  

The name of a secondary index to scan. This index can be any local
secondary index or global secondary index. Note that if you use the
C<IndexName> parameter, you must also provide C<TableName>.










=head2 Limit => Int

  

The maximum number of items to evaluate (not necessarily the number of
matching items). If DynamoDB processes the number of items up to the
limit while processing the results, it stops the operation and returns
the matching values up to that point, and a key in I<LastEvaluatedKey>
to apply in a subsequent operation, so that you can pick up where you
left off. Also, if the processed data set size exceeds 1 MB before
DynamoDB reaches this limit, it stops the operation and returns the
matching values up to the limit, and a key in I<LastEvaluatedKey> to
apply in a subsequent operation to continue the operation. For more
information, see Query and Scan in the I<Amazon DynamoDB Developer
Guide>.










=head2 ProjectionExpression => Str

  

A string that identifies one or more attributes to retrieve from the
specified table or index. These attributes can include scalars, sets,
or elements of a JSON document. The attributes in the expression must
be separated by commas.

If no attribute names are specified, then all attributes will be
returned. If any of the requested attributes are not found, they will
not appear in the result.

For more information, see Accessing Item Attributes in the I<Amazon
DynamoDB Developer Guide>.

I<ProjectionExpression> replaces the legacy I<AttributesToGet>
parameter.










=head2 ReturnConsumedCapacity => Str

  

=head2 ScanFilter => Paws::DynamoDB::FilterConditionMap

  

This is a legacy parameter, for backward compatibility. New
applications should use I<FilterExpression> instead. Do not combine
legacy parameters and expression parameters in a single API call;
otherwise, DynamoDB will return a I<ValidationException> exception.

A condition that evaluates the scan results and returns only the
desired values.

This parameter does not support attributes of type List or Map.

If you specify more than one condition in the I<ScanFilter> map, then
by default all of the conditions must evaluate to true. In other words,
the conditions are ANDed together. (You can use the
I<ConditionalOperator> parameter to OR the conditions instead. If you
do this, then at least one of the conditions must evaluate to true,
rather than all of them.)

Each I<ScanFilter> element consists of an attribute name to compare,
along with the following:

=over

=item *

I<AttributeValueList> - One or more values to evaluate against the
supplied attribute. The number of values in the list depends on the
operator specified in I<ComparisonOperator> .

For type Number, value comparisons are numeric.

String value comparisons for greater than, equals, or less than are
based on ASCII character code values. For example, C<a> is greater than
C<A>, and C<a> is greater than C<B>. For a list of code values, see
http://en.wikipedia.org/wiki/ASCII

For Binary, DynamoDB treats each byte of the binary data as unsigned
when it compares binary values.

For information on specifying data types in JSON, see JSON Data Format
in the I<Amazon DynamoDB Developer Guide>.

=item *

I<ComparisonOperator> - A comparator for evaluating attributes. For
example, equals, greater than, less than, etc.

The following comparison operators are available:

C<EQ | NE | LE | LT | GE | GT | NOT_NULL | NULL | CONTAINS |
NOT_CONTAINS | BEGINS_WITH | IN | BETWEEN>

For complete descriptions of all comparison operators, see Condition.

=back










=head2 Segment => Int

  

For a parallel I<Scan> request, I<Segment> identifies an individual
segment to be scanned by an application worker.

Segment IDs are zero-based, so the first segment is always 0. For
example, if you want to use four application threads to scan a table or
an index, then the first thread specifies a I<Segment> value of 0, the
second thread specifies 1, and so on.

The value of I<LastEvaluatedKey> returned from a parallel I<Scan>
request must be used as I<ExclusiveStartKey> with the same segment ID
in a subsequent I<Scan> operation.

The value for I<Segment> must be greater than or equal to 0, and less
than the value provided for I<TotalSegments>.

If you provide I<Segment>, you must also provide I<TotalSegments>.










=head2 Select => Str

  

The attributes to be returned in the result. You can retrieve all item
attributes, specific item attributes, or the count of matching items.

=over

=item *

C<ALL_ATTRIBUTES> - Returns all of the item attributes.

=item *

C<COUNT> - Returns the number of matching items, rather than the
matching items themselves.

=item *

C<SPECIFIC_ATTRIBUTES> - Returns only the attributes listed in
I<AttributesToGet>. This return value is equivalent to specifying
I<AttributesToGet> without specifying any value for I<Select>.

=back

If neither I<Select> nor I<AttributesToGet> are specified, DynamoDB
defaults to C<ALL_ATTRIBUTES>. You cannot use both I<AttributesToGet>
and I<Select> together in a single request, unless the value for
I<Select> is C<SPECIFIC_ATTRIBUTES>. (This usage is equivalent to
specifying I<AttributesToGet> without any value for I<Select>.)










=head2 B<REQUIRED> TableName => Str

  

The name of the table containing the requested items; or, if you
provide C<IndexName>, the name of the table to which that index
belongs.










=head2 TotalSegments => Int

  

For a parallel I<Scan> request, I<TotalSegments> represents the total
number of segments into which the I<Scan> operation will be divided.
The value of I<TotalSegments> corresponds to the number of application
workers that will perform the parallel scan. For example, if you want
to use four application threads to scan a table or an index, specify a
I<TotalSegments> value of 4.

The value for I<TotalSegments> must be greater than or equal to 1, and
less than or equal to 1000000. If you specify a I<TotalSegments> value
of 1, the I<Scan> operation will be sequential rather than parallel.

If you specify I<TotalSegments>, you must also specify I<Segment>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method Scan in L<Paws::DynamoDB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

