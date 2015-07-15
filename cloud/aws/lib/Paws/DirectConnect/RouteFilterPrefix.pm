package Paws::DirectConnect::RouteFilterPrefix {
  use Moose;
  has cidr => (is => 'ro', isa => 'Str');
}
1;
