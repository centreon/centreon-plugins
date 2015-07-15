
package Paws::DynamoDB::DeleteItemOutput {
  use Moose;
  has Attributes => (is => 'ro', isa => 'Paws::DynamoDB::AttributeMap');
  has ConsumedCapacity => (is => 'ro', isa => 'Paws::DynamoDB::ConsumedCapacity');
  has ItemCollectionMetrics => (is => 'ro', isa => 'Paws::DynamoDB::ItemCollectionMetrics');

}

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDB::DeleteItemOutput

=head1 ATTRIBUTES

=head2 Attributes => Paws::DynamoDB::AttributeMap

  

A map of attribute names to I<AttributeValue> objects, representing the
item as it appeared before the I<DeleteItem> operation. This map
appears in the response only if I<ReturnValues> was specified as
C<ALL_OLD> in the request.









=head2 ConsumedCapacity => Paws::DynamoDB::ConsumedCapacity

  
=head2 ItemCollectionMetrics => Paws::DynamoDB::ItemCollectionMetrics

  

Information about item collections, if any, that were affected by the
operation. I<ItemCollectionMetrics> is only returned if the request
asked for it. If the table does not have any local secondary indexes,
this information is not returned in the response.

Each I<ItemCollectionMetrics> element consists of:

=over

=item *

I<ItemCollectionKey> - The hash key value of the item collection. This
is the same as the hash key of the item.

=item *

I<SizeEstimateRange> - An estimate of item collection size, in
gigabytes. This value is a two-element array containing a lower bound
and an upper bound for the estimate. The estimate includes the size of
all the items in the table, plus the size of all attributes projected
into all of the local secondary indexes on that table. Use this
estimate to measure whether a local secondary index is approaching its
size limit.

The estimate is subject to change over time; therefore, do not rely on
the precision or accuracy of the estimate.

=back











=cut

1;