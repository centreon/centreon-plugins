package Paws::Support::SeverityLevel {
  use Moose;
  has code => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str');
}
1;
