package Paws::Support::Service {
  use Moose;
  has categories => (is => 'ro', isa => 'ArrayRef[Paws::Support::Category]');
  has code => (is => 'ro', isa => 'Str');
  has name => (is => 'ro', isa => 'Str');
}
1;
