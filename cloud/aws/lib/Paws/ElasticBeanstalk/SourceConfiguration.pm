package Paws::ElasticBeanstalk::SourceConfiguration {
  use Moose;
  has ApplicationName => (is => 'ro', isa => 'Str');
  has TemplateName => (is => 'ro', isa => 'Str');
}
1;
