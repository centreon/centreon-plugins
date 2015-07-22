
package Paws::DynamoDB::Query {
  use Moose;
  has AttributesToGet => (is => 'ro', isa => 'ArrayRef[Str]');
  has ConditionalOperator => (is => 'ro', isa => 'Str');
  has ConsistentRead => (is => 'ro', isa => 'Bool');
  has ExclusiveStartKey => (is => 'ro', isa => 'Paws::DynamoDB::Key');
  has ExpressionAttributeNames => (is => 'ro', isa => 'Paws::DynamoDB::ExpressionAttributeNameMap');
  has ExpressionAttributeValues => (is => 'ro', isa => 'Paws::DynamoDB::ExpressionAttributeValueMap');
  has FilterExpression => (is => 'ro', isa => 'Str');
  has IndexName => (is => 'ro', isa => 'Str');
  has KeyConditionExpression => (is => 'ro', isa => 'Str');
  has KeyConditions => (is => 'ro', isa => 'Paws::DynamoDB::KeyConditions');
  has Limit => (is => 'ro', isa => 'Int');
  has ProjectionExpression => (is => 'ro', isa => 'Str');
  has QueryFilter => (is => 'ro', isa => 'Paws::DynamoDB::FilterConditionMap');
  has ReturnConsumedCapacity => (is => 'ro', isa => 'Str');
  has ScanIndexForward => (is => 'ro', isa => 'Bool');
  has Select => (is => 'ro', isa => 'Str');
  has TableName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'Query');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DynamoDB::QueryOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDB::Query - Arguments for method Query on Paws::DynamoDB

=head1 DESCRIPTION

This class represents the parameters used for calling the method Query on the 
Amazon DynamoDB service. Use the attributes of this class
as arguments to method Query.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to Query.

As an example:

  $service_obj->Query(Att1 => $value1, Att2 => $value2, ...);

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

You cannot use both I<AttributesToGet> and I<Select> together in a
I<Query> request, I<unless> the value for I<Select> is
C<SPECIFIC_ATTRIBUTES>. (This usage is equivalent to specifying
I<AttributesToGet> without any value for I<Select>.)

If you query a local secondary index and request only attributes that
are projected into that index, the operation will read only the index
and not the table. If any of the requested attributes are not projected
into the local secondary index, DynamoDB will fetch each of these
attributes from the parent table. This extra fetching incurs additional
throughput cost and latency.

If you query a global secondary index, you can only request attributes
that are projected into the index. Global secondary index queries
cannot fetch attributes from the parent table.










=head2 ConditionalOperator => Str

  

This is a legacy parameter, for backward compatibility. New
applications should use I<FilterExpression> instead. Do not combine
legacy parameters and expression parameters in a single API call;
otherwise, DynamoDB will return a I<ValidationException> exception.

A logical operator to apply to the conditions in a I<QueryFilter> map:

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










=head2 ConsistentRead => Bool

  

Determines the read consistency model: If set to C<true>, then the
operation uses strongly consistent reads; otherwise, the operation uses
eventually consistent reads.

Strongly consistent reads are not supported on global secondary
indexes. If you query a global secondary index with I<ConsistentRead>
set to C<true>, you will receive a I<ValidationException>.










=head2 ExclusiveStartKey => Paws::DynamoDB::Key

  

The primary key of the first item that this operation will evaluate.
Use the value that was returned for I<LastEvaluatedKey> in the previous
operation.

The data type for I<ExclusiveStartKey> must be String, Number or
Binary. No set data types are allowed.










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

For more information on expression attribute names, see Accessing Item
Attributes in the I<Amazon DynamoDB Developer Guide>.










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

For more information on expression attribute values, see Specifying
Conditions in the I<Amazon DynamoDB Developer Guide>.










=head2 FilterExpression => Str

  

A string that contains conditions that DynamoDB applies after the
I<Query> operation, but before the data is returned to you. Items that
do not satisfy the I<FilterExpression> criteria are not returned.

A I<FilterExpression> is applied after the items have already been
read; the process of filtering does not consume any additional read
capacity units.

For more information, see Filter Expressions in the I<Amazon DynamoDB
Developer Guide>.

I<FilterExpression> replaces the legacy I<QueryFilter> and
I<ConditionalOperator> parameters.










=head2 IndexName => Str

  

The name of an index to query. This index can be any local secondary
index or global secondary index on the table. Note that if you use the
I<IndexName> parameter, you must also provide I<TableName.>










=head2 KeyConditionExpression => Str

  

The condition that specifies the key value(s) for items to be retrieved
by the I<Query> action.

The condition must perform an equality test on a single hash key value.
The condition can also perform one of several comparison tests on a
single range key value. I<Query> can use I<KeyConditionExpression> to
retrieve one item with a given hash and range key value, or several
items that have the same hash key value but different range key values.

The hash key equality test is required, and must be specified in the
following format:

C<hashAttributeName> I<=> C<:hashval>

If you also want to provide a range key condition, it must be combined
using I<AND> with the hash key condition. Following is an example,
using the B<=> comparison operator for the range key:

C<hashAttributeName> I<=> C<:hashval> I<AND> C<rangeAttributeName> I<=>
C<:rangeval>

Valid comparisons for the range key condition are as follows:

=over

=item *

C<rangeAttributeName> I<=> C<:rangeval> - true if the range key is
equal to C<:rangeval>.

=item *

C<rangeAttributeName> I<E<lt>> C<:rangeval> - true if the range key is
less than C<:rangeval>.

=item *

C<rangeAttributeName> I<E<lt>=> C<:rangeval> - true if the range key is
less than or equal to C<:rangeval>.

=item *

C<rangeAttributeName> I<E<gt>> C<:rangeval> - true if the range key is
greater than C<:rangeval>.

=item *

C<rangeAttributeName> I<E<gt>= >C<:rangeval> - true if the range key is
greater than or equal to C<:rangeval>.

=item *

C<rangeAttributeName> I<BETWEEN> C<:rangeval1> I<AND> C<:rangeval2> -
true if the range key is greater than or equal to C<:rangeval1>, and
less than or equal to C<:rangeval2>.

=item *

I<begins_with (>C<rangeAttributeName>, C<:rangeval>I<)> - true if the
range key begins with a particular operand. (You cannot use this
function with a range key that is of type Number.) Note that the
function name C<begins_with> is case-sensitive.

=back

Use the I<ExpressionAttributeValues> parameter to replace tokens such
as C<:hashval> and C<:rangeval> with actual values at runtime.

You can optionally use the I<ExpressionAttributeNames> parameter to
replace the names of the hash and range attributes with placeholder
tokens. This option might be necessary if an attribute name conflicts
with a DynamoDB reserved word. For example, the following
I<KeyConditionExpression> parameter causes an error because I<Size> is
a reserved word:

=over

=item * C<Size = :myval>

=back

To work around this, define a placeholder (such a C<
the attribute name I<Size>. I<KeyConditionExpression> then is as
follows:

=over

=item * C<

=back

For a list of reserved words, see Reserved Words in the I<Amazon
DynamoDB Developer Guide>.

For more information on I<ExpressionAttributeNames> and
I<ExpressionAttributeValues>, see Using Placeholders for Attribute
Names and Values in the I<Amazon DynamoDB Developer Guide>.

I<KeyConditionExpression> replaces the legacy I<KeyConditions>
parameter.










=head2 KeyConditions => Paws::DynamoDB::KeyConditions

  

This is a legacy parameter, for backward compatibility. New
applications should use I<KeyConditionExpression> instead. Do not
combine legacy parameters and expression parameters in a single API
call; otherwise, DynamoDB will return a I<ValidationException>
exception.

The selection criteria for the query. For a query on a table, you can
have conditions only on the table primary key attributes. You must
provide the hash key attribute name and value as an C<EQ> condition.
You can optionally provide a second condition, referring to the range
key attribute.

If you don't provide a range key condition, all of the items that match
the hash key will be retrieved. If a I<FilterExpression> or
I<QueryFilter> is present, it will be applied after the items are
retrieved.

For a query on an index, you can have conditions only on the index key
attributes. You must provide the index hash attribute name and value as
an C<EQ> condition. You can optionally provide a second condition,
referring to the index key range attribute.

Each I<KeyConditions> element consists of an attribute name to compare,
along with the following:

=over

=item *

I<AttributeValueList> - One or more values to evaluate against the
supplied attribute. The number of values in the list depends on the
I<ComparisonOperator> being used.

For type Number, value comparisons are numeric.

String value comparisons for greater than, equals, or less than are
based on ASCII character code values. For example, C<a> is greater than
C<A>, and C<a> is greater than C<B>. For a list of code values, see
http://en.wikipedia.org/wiki/ASCII

For Binary, DynamoDB treats each byte of the binary data as unsigned
when it compares binary values.

=item *

I<ComparisonOperator> - A comparator for evaluating attributes, for
example, equals, greater than, less than, and so on.

For I<KeyConditions>, only the following comparison operators are
supported:

C<EQ | LE | LT | GE | GT | BEGINS_WITH | BETWEEN>

The following are descriptions of these comparison operators.

=over

=item *

C<EQ> : Equal.

I<AttributeValueList> can contain only one I<AttributeValue> of type
String, Number, or Binary (not a set type). If an item contains an
I<AttributeValue> element of a different type than the one specified in
the request, the value does not match. For example, C<{"S":"6"}> does
not equal C<{"N":"6"}>. Also, C<{"N":"6"}> does not equal C<{"NS":["6",
"2", "1"]}>.

=item *

C<LE> : Less than or equal.

I<AttributeValueList> can contain only one I<AttributeValue> element of
type String, Number, or Binary (not a set type). If an item contains an
I<AttributeValue> element of a different type than the one provided in
the request, the value does not match. For example, C<{"S":"6"}> does
not equal C<{"N":"6"}>. Also, C<{"N":"6"}> does not compare to
C<{"NS":["6", "2", "1"]}>.

=item *

C<LT> : Less than.

I<AttributeValueList> can contain only one I<AttributeValue> of type
String, Number, or Binary (not a set type). If an item contains an
I<AttributeValue> element of a different type than the one provided in
the request, the value does not match. For example, C<{"S":"6"}> does
not equal C<{"N":"6"}>. Also, C<{"N":"6"}> does not compare to
C<{"NS":["6", "2", "1"]}>.

=item *

C<GE> : Greater than or equal.

I<AttributeValueList> can contain only one I<AttributeValue> element of
type String, Number, or Binary (not a set type). If an item contains an
I<AttributeValue> element of a different type than the one provided in
the request, the value does not match. For example, C<{"S":"6"}> does
not equal C<{"N":"6"}>. Also, C<{"N":"6"}> does not compare to
C<{"NS":["6", "2", "1"]}>.

=item *

C<GT> : Greater than.

I<AttributeValueList> can contain only one I<AttributeValue> element of
type String, Number, or Binary (not a set type). If an item contains an
I<AttributeValue> element of a different type than the one provided in
the request, the value does not match. For example, C<{"S":"6"}> does
not equal C<{"N":"6"}>. Also, C<{"N":"6"}> does not compare to
C<{"NS":["6", "2", "1"]}>.

=item *

C<BEGINS_WITH> : Checks for a prefix.

I<AttributeValueList> can contain only one I<AttributeValue> of type
String or Binary (not a Number or a set type). The target attribute of
the comparison must be of type String or Binary (not a Number or a set
type).

=item *

C<BETWEEN> : Greater than or equal to the first value, and less than or
equal to the second value.

I<AttributeValueList> must contain two I<AttributeValue> elements of
the same type, either String, Number, or Binary (not a set type). A
target attribute matches if the target value is greater than, or equal
to, the first element and less than, or equal to, the second element.
If an item contains an I<AttributeValue> element of a different type
than the one provided in the request, the value does not match. For
example, C<{"S":"6"}> does not compare to C<{"N":"6"}>. Also,
C<{"N":"6"}> does not compare to C<{"NS":["6", "2", "1"]}>

=back

=back

For usage examples of I<AttributeValueList> and I<ComparisonOperator>,
see Legacy Conditional Parameters in the I<Amazon DynamoDB Developer
Guide>.










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
table. These attributes can include scalars, sets, or elements of a
JSON document. The attributes in the expression must be separated by
commas.

If no attribute names are specified, then all attributes will be
returned. If any of the requested attributes are not found, they will
not appear in the result.

For more information, see Accessing Item Attributes in the I<Amazon
DynamoDB Developer Guide>.

I<ProjectionExpression> replaces the legacy I<AttributesToGet>
parameter.










=head2 QueryFilter => Paws::DynamoDB::FilterConditionMap

  

This is a legacy parameter, for backward compatibility. New
applications should use I<FilterExpression> instead. Do not combine
legacy parameters and expression parameters in a single API call;
otherwise, DynamoDB will return a I<ValidationException> exception.

A condition that evaluates the query results after the items are read
and returns only the desired values.

This parameter does not support attributes of type List or Map.

A I<QueryFilter> is applied after the items have already been read; the
process of filtering does not consume any additional read capacity
units.

If you provide more than one condition in the I<QueryFilter> map, then
by default all of the conditions must evaluate to true. In other words,
the conditions are ANDed together. (You can use the
I<ConditionalOperator> parameter to OR the conditions instead. If you
do this, then at least one of the conditions must evaluate to true,
rather than all of them.)

Note that I<QueryFilter> does not allow key attributes. You cannot
define a filter condition on a hash key or range key.

Each I<QueryFilter> element consists of an attribute name to compare,
along with the following:

=over

=item *

I<AttributeValueList> - One or more values to evaluate against the
supplied attribute. The number of values in the list depends on the
operator specified in I<ComparisonOperator>.

For type Number, value comparisons are numeric.

String value comparisons for greater than, equals, or less than are
based on ASCII character code values. For example, C<a> is greater than
C<A>, and C<a> is greater than C<B>. For a list of code values, see
http://en.wikipedia.org/wiki/ASCII

For type Binary, DynamoDB treats each byte of the binary data as
unsigned when it compares binary values.

For information on specifying data types in JSON, see JSON Data Format
in the I<Amazon DynamoDB Developer Guide>.

=item *

I<ComparisonOperator> - A comparator for evaluating attributes. For
example, equals, greater than, less than, etc.

The following comparison operators are available:

C<EQ | NE | LE | LT | GE | GT | NOT_NULL | NULL | CONTAINS |
NOT_CONTAINS | BEGINS_WITH | IN | BETWEEN>

For complete descriptions of all comparison operators, see the
Condition data type.

=back










=head2 ReturnConsumedCapacity => Str

  

=head2 ScanIndexForward => Bool

  

Specifies the order in which to return the query results - either
ascending (C<true>) or descending (C<false>).

Items with the same hash key are stored in sorted order by range key
.If the range key data type is Number, the results are stored in
numeric order. For type String, the results are returned in order of
ASCII character code values. For type Binary, DynamoDB treats each byte
of the binary data as unsigned.

If I<ScanIndexForward> is C<true>, DynamoDB returns the results in
order, by range key. This is the default behavior.

If I<ScanIndexForward> is C<false>, DynamoDB sorts the results in
descending order by range key, and then returns the results to the
client.










=head2 Select => Str

  

The attributes to be returned in the result. You can retrieve all item
attributes, specific item attributes, the count of matching items, or
in the case of an index, some or all of the attributes projected into
the index.

=over

=item *

C<ALL_ATTRIBUTES> - Returns all of the item attributes from the
specified table or index. If you query a local secondary index, then
for each matching item in the index DynamoDB will fetch the entire item
from the parent table. If the index is configured to project all item
attributes, then all of the data can be obtained from the local
secondary index, and no fetching is required.

=item *

C<ALL_PROJECTED_ATTRIBUTES> - Allowed only when querying an index.
Retrieves all attributes that have been projected into the index. If
the index is configured to project all attributes, this return value is
equivalent to specifying C<ALL_ATTRIBUTES>.

=item *

C<COUNT> - Returns the number of matching items, rather than the
matching items themselves.

=item *

C<SPECIFIC_ATTRIBUTES> - Returns only the attributes listed in
I<AttributesToGet>. This return value is equivalent to specifying
I<AttributesToGet> without specifying any value for I<Select>.

If you query a local secondary index and request only attributes that
are projected into that index, the operation will read only the index
and not the table. If any of the requested attributes are not projected
into the local secondary index, DynamoDB will fetch each of these
attributes from the parent table. This extra fetching incurs additional
throughput cost and latency.

If you query a global secondary index, you can only request attributes
that are projected into the index. Global secondary index queries
cannot fetch attributes from the parent table.

=back

If neither I<Select> nor I<AttributesToGet> are specified, DynamoDB
defaults to C<ALL_ATTRIBUTES> when accessing a table, and
C<ALL_PROJECTED_ATTRIBUTES> when accessing an index. You cannot use
both I<Select> and I<AttributesToGet> together in a single request,
unless the value for I<Select> is C<SPECIFIC_ATTRIBUTES>. (This usage
is equivalent to specifying I<AttributesToGet> without any value for
I<Select>.)

If you use the I<ProjectionExpression> parameter, then the value for
I<Select> can only be C<SPECIFIC_ATTRIBUTES>. Any other value for
I<Select> will return an error.










=head2 B<REQUIRED> TableName => Str

  

The name of the table containing the requested items.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method Query in L<Paws::DynamoDB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

