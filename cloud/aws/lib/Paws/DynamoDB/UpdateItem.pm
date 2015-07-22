
package Paws::DynamoDB::UpdateItem {
  use Moose;
  has AttributeUpdates => (is => 'ro', isa => 'Paws::DynamoDB::AttributeUpdates');
  has ConditionalOperator => (is => 'ro', isa => 'Str');
  has ConditionExpression => (is => 'ro', isa => 'Str');
  has Expected => (is => 'ro', isa => 'Paws::DynamoDB::ExpectedAttributeMap');
  has ExpressionAttributeNames => (is => 'ro', isa => 'Paws::DynamoDB::ExpressionAttributeNameMap');
  has ExpressionAttributeValues => (is => 'ro', isa => 'Paws::DynamoDB::ExpressionAttributeValueMap');
  has Key => (is => 'ro', isa => 'Paws::DynamoDB::Key', required => 1);
  has ReturnConsumedCapacity => (is => 'ro', isa => 'Str');
  has ReturnItemCollectionMetrics => (is => 'ro', isa => 'Str');
  has ReturnValues => (is => 'ro', isa => 'Str');
  has TableName => (is => 'ro', isa => 'Str', required => 1);
  has UpdateExpression => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateItem');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::DynamoDB::UpdateItemOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDB::UpdateItem - Arguments for method UpdateItem on Paws::DynamoDB

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateItem on the 
Amazon DynamoDB service. Use the attributes of this class
as arguments to method UpdateItem.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateItem.

As an example:

  $service_obj->UpdateItem(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AttributeUpdates => Paws::DynamoDB::AttributeUpdates

  

This is a legacy parameter, for backward compatibility. New
applications should use I<UpdateExpression> instead. Do not combine
legacy parameters and expression parameters in a single API call;
otherwise, DynamoDB will return a I<ValidationException> exception.

This parameter can be used for modifying top-level attributes; however,
it does not support individual list or map elements.

The names of attributes to be modified, the action to perform on each,
and the new value for each. If you are updating an attribute that is an
index key attribute for any indexes on that table, the attribute type
must match the index key type defined in the I<AttributesDefinition> of
the table description. You can use I<UpdateItem> to update any nonkey
attributes.

Attribute values cannot be null. String and Binary type attributes must
have lengths greater than zero. Set type attributes must not be empty.
Requests with empty values will be rejected with a
I<ValidationException> exception.

Each I<AttributeUpdates> element consists of an attribute name to
modify, along with the following:

=over

=item *

I<Value> - The new value, if applicable, for this attribute.

=item *

I<Action> - A value that specifies how to perform the update. This
action is only valid for an existing attribute whose data type is
Number or is a set; do not use C<ADD> for other data types.

If an item with the specified primary key is found in the table, the
following values perform the following actions:

=over

=item *

C<PUT> - Adds the specified attribute to the item. If the attribute
already exists, it is replaced by the new value.

=item *

C<DELETE> - Removes the attribute and its value, if no value is
specified for C<DELETE>. The data type of the specified value must
match the existing value's data type.

If a set of values is specified, then those values are subtracted from
the old set. For example, if the attribute value was the set C<[a,b,c]>
and the C<DELETE> action specifies C<[a,c]>, then the final attribute
value is C<[b]>. Specifying an empty set is an error.

=item *

C<ADD> - Adds the specified value to the item, if the attribute does
not already exist. If the attribute does exist, then the behavior of
C<ADD> depends on the data type of the attribute:

=over

=item *

If the existing attribute is a number, and if I<Value> is also a
number, then I<Value> is mathematically added to the existing
attribute. If I<Value> is a negative number, then it is subtracted from
the existing attribute.

If you use C<ADD> to increment or decrement a number value for an item
that doesn't exist before the update, DynamoDB uses 0 as the initial
value.

Similarly, if you use C<ADD> for an existing item to increment or
decrement an attribute value that doesn't exist before the update,
DynamoDB uses C<0> as the initial value. For example, suppose that the
item you want to update doesn't have an attribute named I<itemcount>,
but you decide to C<ADD> the number C<3> to this attribute anyway.
DynamoDB will create the I<itemcount> attribute, set its initial value
to C<0>, and finally add C<3> to it. The result will be a new
I<itemcount> attribute, with a value of C<3>.

=item *

If the existing data type is a set, and if I<Value> is also a set, then
I<Value> is appended to the existing set. For example, if the attribute
value is the set C<[1,2]>, and the C<ADD> action specified C<[3]>, then
the final attribute value is C<[1,2,3]>. An error occurs if an C<ADD>
action is specified for a set attribute and the attribute type
specified does not match the existing set type.

Both sets must have the same primitive data type. For example, if the
existing data type is a set of strings, I<Value> must also be a set of
strings.

=back

=back

If no item with the specified key is found in the table, the following
values perform the following actions:

=over

=item *

C<PUT> - Causes DynamoDB to create a new item with the specified
primary key, and then adds the attribute.

=item *

C<DELETE> - Nothing happens, because attributes cannot be deleted from
a nonexistent item. The operation succeeds, but DynamoDB does not
create a new item.

=item *

C<ADD> - Causes DynamoDB to create an item with the supplied primary
key and number (or set of numbers) for the attribute value. The only
data types allowed are Number and Number Set.

=back

=back

If you provide any attributes that are part of an index key, then the
data types for those attributes must match those of the schema in the
table's attribute definition.










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

  

A condition that must be satisfied in order for a conditional update to
succeed.

An expression can contain any of the following:

=over

=item *

Functions: C<attribute_exists | attribute_not_exists | attribute_type |
contains | begins_with | size>

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
applications should use I< ConditionExpression > instead. Do not
combine legacy parameters and expression parameters in a single API
call; otherwise, DynamoDB will return a I<ValidationException>
exception.

A map of attribute/condition pairs. I<Expected> provides a conditional
block for the I<UpdateItem> operation.

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

This parameter does not support attributes of type List or Map.










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










=head2 B<REQUIRED> Key => Paws::DynamoDB::Key

  

The primary key of the item to be updated. Each element consists of an
attribute name and a value for that attribute.

For the primary key, you must provide all of the attributes. For
example, with a hash type primary key, you only need to provide the
hash attribute. For a hash-and-range type primary key, you must provide
both the hash attribute and the range attribute.










=head2 ReturnConsumedCapacity => Str

  

=head2 ReturnItemCollectionMetrics => Str

  

Determines whether item collection metrics are returned. If set to
C<SIZE>, the response includes statistics about item collections, if
any, that were modified during the operation are returned in the
response. If set to C<NONE> (the default), no statistics are returned.










=head2 ReturnValues => Str

  

Use I<ReturnValues> if you want to get the item attributes as they
appeared either before or after they were updated. For I<UpdateItem>,
the valid values are:

=over

=item *

C<NONE> - If I<ReturnValues> is not specified, or if its value is
C<NONE>, then nothing is returned. (This setting is the default for
I<ReturnValues>.)

=item *

C<ALL_OLD> - If I<UpdateItem> overwrote an attribute name-value pair,
then the content of the old item is returned.

=item *

C<UPDATED_OLD> - The old versions of only the updated attributes are
returned.

=item *

C<ALL_NEW> - All of the attributes of the new version of the item are
returned.

=item *

C<UPDATED_NEW> - The new versions of only the updated attributes are
returned.

=back










=head2 B<REQUIRED> TableName => Str

  

The name of the table containing the item to update.










=head2 UpdateExpression => Str

  

An expression that defines one or more attributes to be updated, the
action to be performed on them, and new value(s) for them.

The following action values are available for I<UpdateExpression>.

=over

=item *

C<SET> - Adds one or more attributes and values to an item. If any of
these attribute already exist, they are replaced by the new values. You
can also use C<SET> to add or subtract from an attribute that is of
type Number. For example: C<SET myNum = myNum + :val>

C<SET> supports the following functions:

=over

=item *

C<if_not_exists (path, operand)> - if the item does not contain an
attribute at the specified path, then C<if_not_exists> evaluates to
operand; otherwise, it evaluates to path. You can use this function to
avoid overwriting an attribute that may already be present in the item.

=item *

C<list_append (operand, operand)> - evaluates to a list with a new
element added to it. You can append the new element to the start or the
end of the list by reversing the order of the operands.

=back

These function names are case-sensitive.

=item *

C<REMOVE> - Removes one or more attributes from an item.

=item *

C<ADD> - Adds the specified value to the item, if the attribute does
not already exist. If the attribute does exist, then the behavior of
C<ADD> depends on the data type of the attribute:

=over

=item *

If the existing attribute is a number, and if I<Value> is also a
number, then I<Value> is mathematically added to the existing
attribute. If I<Value> is a negative number, then it is subtracted from
the existing attribute.

If you use C<ADD> to increment or decrement a number value for an item
that doesn't exist before the update, DynamoDB uses C<0> as the initial
value.

Similarly, if you use C<ADD> for an existing item to increment or
decrement an attribute value that doesn't exist before the update,
DynamoDB uses C<0> as the initial value. For example, suppose that the
item you want to update doesn't have an attribute named I<itemcount>,
but you decide to C<ADD> the number C<3> to this attribute anyway.
DynamoDB will create the I<itemcount> attribute, set its initial value
to C<0>, and finally add C<3> to it. The result will be a new
I<itemcount> attribute in the item, with a value of C<3>.

=item *

If the existing data type is a set and if I<Value> is also a set, then
I<Value> is added to the existing set. For example, if the attribute
value is the set C<[1,2]>, and the C<ADD> action specified C<[3]>, then
the final attribute value is C<[1,2,3]>. An error occurs if an C<ADD>
action is specified for a set attribute and the attribute type
specified does not match the existing set type.

Both sets must have the same primitive data type. For example, if the
existing data type is a set of strings, the I<Value> must also be a set
of strings.

=back

The C<ADD> action only supports Number and set data types. In addition,
C<ADD> can only be used on top-level attributes, not nested attributes.

=item *

C<DELETE> - Deletes an element from a set.

If a set of values is specified, then those values are subtracted from
the old set. For example, if the attribute value was the set C<[a,b,c]>
and the C<DELETE> action specifies C<[a,c]>, then the final attribute
value is C<[b]>. Specifying an empty set is an error.

The C<DELETE> action only supports set data types. In addition,
C<DELETE> can only be used on top-level attributes, not nested
attributes.

=back

You can have many actions in a single expression, such as the
following: C<SET a=:value1, b=:value2 DELETE :value3, :value4, :value5>

For more information on update expressions, see Modifying Items and
Attributes in the I<Amazon DynamoDB Developer Guide>.

I<UpdateExpression> replaces the legacy I<AttributeUpdates> parameter.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateItem in L<Paws::DynamoDB>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

