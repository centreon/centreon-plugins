package Paws::DynamoDB::StreamSpecification {
  use Moose;
  has StreamEnabled => (is => 'ro', isa => 'Bool');
  has StreamViewType => (is => 'ro', isa => 'Str');
}
1;
