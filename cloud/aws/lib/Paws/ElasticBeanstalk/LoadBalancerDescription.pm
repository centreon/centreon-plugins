package Paws::ElasticBeanstalk::LoadBalancerDescription {
  use Moose;
  has Domain => (is => 'ro', isa => 'Str');
  has Listeners => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::Listener]');
  has LoadBalancerName => (is => 'ro', isa => 'Str');
}
1;
