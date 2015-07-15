package Paws::ELB::ConnectionSettings {
  use Moose;
  has IdleTimeout => (is => 'ro', isa => 'Int', required => 1);
}
1;
