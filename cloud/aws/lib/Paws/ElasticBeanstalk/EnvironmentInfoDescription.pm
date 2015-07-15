package Paws::ElasticBeanstalk::EnvironmentInfoDescription {
  use Moose;
  has Ec2InstanceId => (is => 'ro', isa => 'Str');
  has InfoType => (is => 'ro', isa => 'Str');
  has Message => (is => 'ro', isa => 'Str');
  has SampleTimestamp => (is => 'ro', isa => 'Str');
}
1;
