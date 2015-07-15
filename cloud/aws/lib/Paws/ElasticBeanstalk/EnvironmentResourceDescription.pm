package Paws::ElasticBeanstalk::EnvironmentResourceDescription {
  use Moose;
  has AutoScalingGroups => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::AutoScalingGroup]');
  has EnvironmentName => (is => 'ro', isa => 'Str');
  has Instances => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::Instance]');
  has LaunchConfigurations => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::LaunchConfiguration]');
  has LoadBalancers => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::LoadBalancer]');
  has Queues => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::Queue]');
  has Triggers => (is => 'ro', isa => 'ArrayRef[Paws::ElasticBeanstalk::Trigger]');
}
1;
