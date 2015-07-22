
package Paws::DynamoDBStreams::ListStreamsOutput {
  use Moose;
  has LastEvaluatedStreamArn => (is => 'ro', isa => 'Str');
  has Streams => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDBStreams::Stream]');

}

### main pod documentation begin ###

=head1 NAME

Paws::DynamoDBStreams::ListStreamsOutput

=head1 ATTRIBUTES

=head2 LastEvaluatedStreamArn => Str

  

The stream ARN of the item where the operation stopped, inclusive of
the previous result set. Use this value to start a new operation,
excluding this value in the new request.

If C<LastEvaluatedStreamArn> is empty, then the "last page" of results
has been processed and there is no more data to be retrieved.

If C<LastEvaluatedStreamArn> is not empty, it does not necessarily mean
that there is more data in the result set. The only way to know when
you have reached the end of the result set is when
C<LastEvaluatedStreamArn> is empty.









=head2 Streams => ArrayRef[Paws::DynamoDBStreams::Stream]

  

A list of stream descriptors associated with the current account and
endpoint.











=cut

1;