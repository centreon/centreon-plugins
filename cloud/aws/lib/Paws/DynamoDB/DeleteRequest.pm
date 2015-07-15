package Paws::DynamoDB::DeleteRequest {
  use Moose;
  has Key => (is => 'ro', isa => 'Paws::DynamoDB::Key', required => 1);
}
1;
