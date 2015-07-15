package Paws::RedShift::ClusterNode {
  use Moose;
  has NodeRole => (is => 'ro', isa => 'Str');
  has PrivateIPAddress => (is => 'ro', isa => 'Str');
  has PublicIPAddress => (is => 'ro', isa => 'Str');
}
1;
