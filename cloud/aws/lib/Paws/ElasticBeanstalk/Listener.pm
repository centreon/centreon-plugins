package Paws::ElasticBeanstalk::Listener {
  use Moose;
  has Port => (is => 'ro', isa => 'Int');
  has Protocol => (is => 'ro', isa => 'Str');
}
1;
