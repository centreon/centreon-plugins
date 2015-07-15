package Paws::SNS::Endpoint {
  use Moose;
  has Attributes => (is => 'ro', isa => 'Paws::SNS::MapStringToString');
  has EndpointArn => (is => 'ro', isa => 'Str');
}
1;
