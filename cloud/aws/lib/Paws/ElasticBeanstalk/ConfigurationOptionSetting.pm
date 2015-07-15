package Paws::ElasticBeanstalk::ConfigurationOptionSetting {
  use Moose;
  has Namespace => (is => 'ro', isa => 'Str');
  has OptionName => (is => 'ro', isa => 'Str');
  has ResourceName => (is => 'ro', isa => 'Str');
  has Value => (is => 'ro', isa => 'Str');
}
1;
