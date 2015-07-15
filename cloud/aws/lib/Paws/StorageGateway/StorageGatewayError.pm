package Paws::StorageGateway::StorageGatewayError {
  use Moose;
  has errorCode => (is => 'ro', isa => 'Str');
  has errorDetails => (is => 'ro', isa => 'Paws::StorageGateway::errorDetails');
}
1;
