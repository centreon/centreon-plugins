package Paws::ElasticBeanstalk::ValidationMessage {
  use Moose;
  has Message => (is => 'ro', isa => 'Str');
  has Namespace => (is => 'ro', isa => 'Str');
  has OptionName => (is => 'ro', isa => 'Str');
  has Severity => (is => 'ro', isa => 'Str');
}
1;
