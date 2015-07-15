package Paws::DynamoDB::Projection {
  use Moose;
  has NonKeyAttributes => (is => 'ro', isa => 'ArrayRef[Str]');
  has ProjectionType => (is => 'ro', isa => 'Str');
}
1;
