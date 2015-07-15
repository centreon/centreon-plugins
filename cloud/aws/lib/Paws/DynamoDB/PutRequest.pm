package Paws::DynamoDB::PutRequest {
  use Moose;
  has Item => (is => 'ro', isa => 'Paws::DynamoDB::PutItemInputAttributeMap', required => 1);
}
1;
