package Paws::ElasticBeanstalk::OptionSpecification {
  use Moose;
  has Namespace => (is => 'ro', isa => 'Str');
  has OptionName => (is => 'ro', isa => 'Str');
  has ResourceName => (is => 'ro', isa => 'Str');
}
1;
