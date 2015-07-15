package Paws::ELB::Listener {
  use Moose;
  has InstancePort => (is => 'ro', isa => 'Int', required => 1);
  has InstanceProtocol => (is => 'ro', isa => 'Str');
  has LoadBalancerPort => (is => 'ro', isa => 'Int', required => 1);
  has Protocol => (is => 'ro', isa => 'Str', required => 1);
  has SSLCertificateId => (is => 'ro', isa => 'Str');
}
1;
