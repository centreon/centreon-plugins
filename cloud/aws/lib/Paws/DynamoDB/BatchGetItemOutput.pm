
package Paws::DynamoDB::BatchGetItemOutput {
  use Moose;
  has ConsumedCapacity => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::ConsumedCapacity]');
  has Responses => (is => 'ro', isa => 'Paws::DynamoDB::BatchGetResponseMap');
  has UnprocessedKeys => (is => 'ro', isa => 'Paws::DynamoDB::BatchGetRequestMap');

}

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDB::BatchGetItemOutput

=head1 ATTRIBUTES

=head2 ConsumedCapacity => ArrayRef[Paws::DynamoDB::ConsumedCapacity]

  

The read capacity units consumed by the operation.

Each element consists of:

=over

=item *

I<TableName> - The table that consumed the provisioned throughput.

=item *

I<CapacityUnits> - The total number of capacity units consumed.

=back









=head2 Responses => Paws::DynamoDB::BatchGetResponseMap

  

A map of table name to a list of items. Each object in I<Responses>
consists of a table name, along with a map of attribute data consisting
of the data type and attribute value.









=head2 UnprocessedKeys => Paws::DynamoDB::BatchGetRequestMap

  

A map of tables and their respective keys that were not processed with
the current response. The I<UnprocessedKeys> value is in the same form
as I<RequestItems>, so the value can be provided directly to a
subsequent I<BatchGetItem> operation. For more information, see
I<RequestItems> in the Request Parameters section.

Each element consists of:

=over

=item *

I<Keys> - An array of primary key attribute values that define specific
items in the table.

=item *

I<AttributesToGet> - One or more attributes to be retrieved from the
table or index. By default, all attributes are returned. If a requested
attribute is not found, it does not appear in the result.

=item *

I<ConsistentRead> - The consistency of a read operation. If set to
C<true>, then a strongly consistent read is used; otherwise, an
eventually consistent read is used.

=back

If there are no unprocessed keys remaining, the response contains an
empty I<UnprocessedKeys> map.











=cut

1;