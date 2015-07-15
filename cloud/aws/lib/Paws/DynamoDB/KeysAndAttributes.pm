package Paws::DynamoDB::KeysAndAttributes {
  use Moose;
  has AttributesToGet => (is => 'ro', isa => 'ArrayRef[Str]');
  has ConsistentRead => (is => 'ro', isa => 'Bool');
  has ExpressionAttributeNames => (is => 'ro', isa => 'Paws::DynamoDB::ExpressionAttributeNameMap');
  has Keys => (is => 'ro', isa => 'ArrayRef[Paws::DynamoDB::Key]', required => 1);
  has ProjectionExpression => (is => 'ro', isa => 'Str');
}
1;
