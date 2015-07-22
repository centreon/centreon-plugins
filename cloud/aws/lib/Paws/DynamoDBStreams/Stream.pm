package Paws::DynamoDBStreams::Stream {
  use Moose;
  has StreamArn => (is => 'ro', isa => 'Str');
  has StreamLabel => (is => 'ro', isa => 'Str');
  has TableName => (is => 'ro', isa => 'Str');
}
1;
