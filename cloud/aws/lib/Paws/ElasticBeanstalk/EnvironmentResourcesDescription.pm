package Paws::ElasticBeanstalk::EnvironmentResourcesDescription {
  use Moose;
  has LoadBalancer => (is => 'ro', isa => 'Paws::ElasticBeanstalk::LoadBalancerDescription');
}
1;
