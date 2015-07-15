package Paws::RedShift::ElasticIpStatus {
  use Moose;
  has ElasticIp => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
}
1;
