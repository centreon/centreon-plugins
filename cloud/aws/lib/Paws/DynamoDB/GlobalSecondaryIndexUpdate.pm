package Paws::DynamoDB::GlobalSecondaryIndexUpdate {
  use Moose;
  has Create => (is => 'ro', isa => 'Paws::DynamoDB::CreateGlobalSecondaryIndexAction');
  has Delete => (is => 'ro', isa => 'Paws::DynamoDB::DeleteGlobalSecondaryIndexAction');
  has Update => (is => 'ro', isa => 'Paws::DynamoDB::UpdateGlobalSecondaryIndexAction');
}
1;
