
package Paws::DynamoDB::PutItem {
  use Moose;
  has ConditionalOperator => (is => 'ro', isa => 'Str');
  has ConditionExpression => (is => 'ro', isa => 'Str');
  has Expected => (is => 'ro', isa => 'Paws::DynamoDB::ExpectedAttributeMap');
  has ExpressionAttributeNames => (is => 'ro', isa => 'Paws::DynamoDB::ExpressionAttributeNameMap');
  has ExpressionAttributeValues => (is => 'ro', isa => 'Paws::DynamoDB::ExpressionAttributeValueMap');
  has Item => (is => 'ro', isa => 'Paws::DynamoDB::PutItemInputAttributeMap', required => 1);
  has ReturnConsumedCapacity => (is => 'ro', isa => 'Str');
  has ReturnItemCollectionMetrics => (is => 'ro', isa => 'Str');
  has ReturnValues => (is => 'ro', isa => 'Str');
  has TableName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PutItem');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DynamoDB::PutItemOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDB::PutItem - Arguments for method PutItem on Paws::DynamoDB

=head1 DESCRIPTION

This class represents the parameters used for calling the method PutItem on the 
Amazon DynamoDB service. Use the attributes of this class
as arguments to method PutItem.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PutItem.

As an example:

  $service_obj->PutItem(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ConditionalOperator => Str

  

This is a legacy parameter, for backward compatibility. New
applications should use I<ConditionExpression> instead. Do not combine
legacy parameters and expression parameters in a single API call;
otherwise, DynamoDB will return a I<ValidationException> exception.

A logical operator to apply to the conditions in the I<Expected> map:

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










=head2 ConditionExpression => Str

  

A condition that must be satisfied in order for a conditional
I<PutItem> operation to succeed.

An expression can contain any of the following:

=over

=item *

Boolean functions: C<attribute_exists | attribute_not_exists | contains
| begins_with>

These function names are case-sensitive.

=item *

Comparison operators: C< = | E<lt>E<gt> | E<lt> | E<gt> | E<lt>= |
E<gt>= | BETWEEN | IN>

=item *

Logical operators: C<AND | OR | NOT>

=back

For more information on condition expressions, see Specifying
Conditions in the I<Amazon DynamoDB Developer Guide>.

I<ConditionExpression> replaces the legacy I<ConditionalOperator> and
I<Expected> parameters.










=head2 Expected => Paws::DynamoDB::ExpectedAttributeMap

  

This is a legacy parameter, for backward compatibility. New
applications should use I<ConditionExpression> instead. Do not combine
legacy parameters and expression parameters in a single API call;
otherwise, DynamoDB will return a I<ValidationException> exception.

A map of attribute/condition pairs. I<Expected> provides a conditional
block for the I<PutItem> operation.

This parameter does not support attributes of type List or Map.

Each element of I<Expected> consists of an attribute name, a comparison
operator, and one or more values. DynamoDB compares the attribute with
the value(s) you supplied, using the comparison operator. For each
I<Expected> element, the result of the evaluation is either true or
false.

If you specify more than one element in the I<Expected> map, then by
default all of the conditions must evaluate to true. In other words,
the conditions are ANDed together. (You can use the
I<ConditionalOperator> parameter to OR the conditions instead. If you
do this, then at least one of the conditions must evaluate to true,
rather than all of them.)

If the I<Expected> map evaluates to true, then the conditional
operation succeeds; otherwise, it fails.

I<Expected> contains the following:

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

For type Binary, DynamoDB treats each byte of the binary data as
unsigned when it compares binary values.

=item *

I<ComparisonOperator> - A comparator for evaluating attributes in the
I<AttributeValueList>. When performing the comparison, DynamoDB uses
strongly consistent reads.

The following comparison operators are available:

C<EQ | NE | LE | LT | GE | GT | NOT_NULL | NULL | CONTAINS |
NOT_CONTAINS | BEGINS_WITH | IN | BETWEEN>

The following are descriptions of each comparison operator.

=over

=item *

C<EQ> : Equal. C<EQ> is supported for all datatypes, including lists
and maps.

I<AttributeValueList> can contain only one I<AttributeValue> element of
type String, Number, Binary, String Set, Number Set, or Binary Set. If
an item contains an I<AttributeValue> element of a different type than
the one provided in the request, the value does not match. For example,
C<{"S":"6"}> does not equal C<{"N":"6"}>. Also, C<{"N":"6"}> does not
equal C<{"NS":["6", "2", "1"]}>.

=item *

C<NE> : Not equal. C<NE> is supported for all datatypes, including
lists and maps.

I<AttributeValueList> can contain only one I<AttributeValue> of type
String, Number, Binary, String Set, Number Set, or Binary Set. If an
item contains an I<AttributeValue> of a different type than the one
provided in the request, the value does not match. For example,
C<{"S":"6"}> does not equal C<{"N":"6"}>. Also, C<{"N":"6"}> does not
equal C<{"NS":["6", "2", "1"]}>.

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

C<NOT_NULL> : The attribute exists. C<NOT_NULL> is supported for all
datatypes, including lists and maps.

This operator tests for the existence of an attribute, not its data
type. If the data type of attribute "C<a>" is null, and you evaluate it
using C<NOT_NULL>, the result is a Boolean I<true>. This result is
because the attribute "C<a>" exists; its data type is not relevant to
the C<NOT_NULL> comparison operator.

=item *

C<NULL> : The attribute does not exist. C<NULL> is supported for all
datatypes, including lists and maps.

This operator tests for the nonexistence of an attribute, not its data
type. If the data type of attribute "C<a>" is null, and you evaluate it
using C<NULL>, the result is a Boolean I<false>. This is because the
attribute "C<a>" exists; its data type is not relevant to the C<NULL>
comparison operator.

=item *

C<CONTAINS> : Checks for a subsequence, or value in a set.

I<AttributeValueList> can contain only one I<AttributeValue> element of
type String, Number, or Binary (not a set type). If the target
attribute of the comparison is of type String, then the operator checks
for a substring match. If the target attribute of the comparison is of
type Binary, then the operator looks for a subsequence of the target
that matches the input. If the target attribute of the comparison is a
set ("C<SS>", "C<NS>", or "C<BS>"), then the operator evaluates to true
if it finds an exact match with any member of the set.

CONTAINS is supported for lists: When evaluating "C<a CONTAINS b>",
"C<a>" can be a list; however, "C<b>" cannot be a set, a map, or a
list.

=item *

C<NOT_CONTAINS> : Checks for absence of a subsequence, or absence of a
value in a set.

I<AttributeValueList> can contain only one I<AttributeValue> element of
type String, Number, or Binary (not a set type). If the target
attribute of the comparison is a String, then the operator checks for
the absence of a substring match. If the target attribute of the
comparison is Binary, then the operator checks for the absence of a
subsequence of the target that matches the input. If the target
attribute of the comparison is a set ("C<SS>", "C<NS>", or "C<BS>"),
then the operator evaluates to true if it I<does not> find an exact
match with any member of the set.

NOT_CONTAINS is supported for lists: When evaluating "C<a NOT CONTAINS
b>", "C<a>" can be a list; however, "C<b>" cannot be a set, a map, or a
list.

=item *

C<BEGINS_WITH> : Checks for a prefix.

I<AttributeValueList> can contain only one I<AttributeValue> of type
String or Binary (not a Number or a set type). The target attribute of
the comparison must be of type String or Binary (not a Number or a set
type).

=item *

C<IN> : Checks for matching elements within two sets.

I<AttributeValueList> can contain one or more I<AttributeValue>
elements of type String, Number, or Binary (not a set type). These
attributes are compared against an existing set type attribute of an
item. If any elements of the input set are present in the item
attribute, the expression evaluates to true.

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

For backward compatibility with previous DynamoDB releases, the
following parameters can be used instead of I<AttributeValueList> and
I<ComparisonOperator>:

=over

=item *

I<Value> - A value for DynamoDB to compare with an attribute.

=item *

I<Exists> - A Boolean value that causes DynamoDB to evaluate the value
before attempting the conditional operation:

=over

=item *

If I<Exists> is C<true>, DynamoDB will check to see if that attribute
value already exists in the table. If it is found, then the condition
evaluates to true; otherwise the condition evaluate to false.

=item *

If I<Exists> is C<false>, DynamoDB assumes that the attribute value
does I<not> exist in the table. If in fact the value does not exist,
then the assumption is valid and the condition evaluates to true. If
the value is found, despite the assumption that it does not exist, the
condition evaluates to false.

=back

Note that the default value for I<Exists> is C<true>.

=back

The I<Value> and I<Exists> parameters are incompatible with
I<AttributeValueList> and I<ComparisonOperator>. Note that if you use
both sets of parameters at once, DynamoDB will return a
I<ValidationException> exception.










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










=head2 B<REQUIRED> Item => Paws::DynamoDB::PutItemInputAttributeMap

  

A map of attribute name/value pairs, one for each attribute. Only the
primary key attributes are required; you can optionally provide other
attribute name-value pairs for the item.

You must provide all of the attributes for the primary key. For
example, with a hash type primary key, you only need to provide the
hash attribute. For a hash-and-range type primary key, you must provide
both the hash attribute and the range attribute.

If you specify any attributes that are part of an index key, then the
data types for those attributes must match those of the schema in the
table's attribute definition.

For more information about primary keys, see Primary Key in the
I<Amazon DynamoDB Developer Guide>.

Each element in the I<Item> map is an I<AttributeValue> object.










=head2 ReturnConsumedCapacity => Str

  

=head2 ReturnItemCollectionMetrics => Str

  

A value that if set to C<SIZE>, the response includes statistics about
item collections, if any, that were modified during the operation are
returned in the response. If set to C<NONE> (the default), no
statistics are returned.










=head2 ReturnValues => Str

  

Use I<ReturnValues> if you want to get the item attributes as they
appeared before they were updated with the I<PutItem> request. For
I<PutItem>, the valid values are:

=over

=item *

C<NONE> - If I<ReturnValues> is not specified, or if its value is
C<NONE>, then nothing is returned. (This setting is the default for
I<ReturnValues>.)

=item *

C<ALL_OLD> - If I<PutItem> overwrote an attribute name-value pair, then
the content of the old item is returned.

=back










=head2 B<REQUIRED> TableName => Str

  

The name of the table to contain the item.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PutItem in L<Paws::DynamoDB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

