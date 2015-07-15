package Paws::DynamoDB::WriteRequest {
  use Moose;
  has DeleteRequest => (is => 'ro', isa => 'Paws::DynamoDB::DeleteRequest');
  has PutRequest => (is => 'ro', isa => 'Paws::DynamoDB::PutRequest');
}
1;
