package Paws::ElasticBeanstalk::OptionRestrictionRegex {
  use Moose;
  has Label => (is => 'ro', isa => 'Str');
  has Pattern => (is => 'ro', isa => 'Str');
}
1;
