
package Paws::DynamoDB::ScanOutput {
  use Moose;
  has ConsumedCapacity => (is => 'ro', isa => 'Paws::DynamoDB::ConsumedCapacity');
  has Count => (is => 'ro', isa => 'Int');
  has Items => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::AttributeMap]');
  has LastEvaluatedKey => (is => 'ro', isa => 'Paws::DynamoDB::Key');
  has ScannedCount => (is => 'ro', isa => 'Int');

}

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDB::ScanOutput

=head1 ATTRIBUTES

=head2 ConsumedCapacity => Paws::DynamoDB::ConsumedCapacity

  
=head2 Count => Int

  

The number of items in the response.

If you set I<ScanFilter> in the request, then I<Count> is the number of
items returned after the filter was applied, and I<ScannedCount> is the
number of matching items before the filter was applied.

If you did not use a filter in the request, then I<Count> is the same
as I<ScannedCount>.









=head2 Items => ArrayRef[Paws::DynamoDB::AttributeMap]

  

An array of item attributes that match the scan criteria. Each element
in this array consists of an attribute name and the value for that
attribute.









=head2 LastEvaluatedKey => Paws::DynamoDB::Key

  

The primary key of the item where the operation stopped, inclusive of
the previous result set. Use this value to start a new operation,
excluding this value in the new request.

If I<LastEvaluatedKey> is empty, then the "last page" of results has
been processed and there is no more data to be retrieved.

If I<LastEvaluatedKey> is not empty, it does not necessarily mean that
there is more data in the result set. The only way to know when you
have reached the end of the result set is when I<LastEvaluatedKey> is
empty.









=head2 ScannedCount => Int

  

The number of items evaluated, before any I<ScanFilter> is applied. A
high I<ScannedCount> value with few, or no, I<Count> results indicates
an inefficient I<Scan> operation. For more information, see Count and
ScannedCount in the I<Amazon DynamoDB Developer Guide>.

If you did not use a filter in the request, then I<ScannedCount> is the
same as I<Count>.











=cut

1;