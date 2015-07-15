package Paws::ElasticBeanstalk::EnvironmentTier {
  use Moose;
  has Name => (is => 'ro', isa => 'Str');
  has Type => (is => 'ro', isa => 'Str');
  has Version => (is => 'ro', isa => 'Str');
}
1;
