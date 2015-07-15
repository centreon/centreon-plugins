package Paws::DynamoDB::DeleteGlobalSecondaryIndexAction {
  use Moose;
  has IndexName => (is => 'ro', isa => 'Str', required => 1);
}
1;
