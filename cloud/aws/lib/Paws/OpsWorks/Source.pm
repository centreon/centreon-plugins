package Paws::OpsWorks::Source {
  use Moose;
  has Password => (is => 'ro', isa => 'Str');
  has Revision => (is => 'ro', isa => 'Str');
  has SshKey => (is => 'ro', isa => 'Str');
  has Type => (is => 'ro', isa => 'Str');
  has Url => (is => 'ro', isa => 'Str');
  has Username => (is => 'ro', isa => 'Str');
}
1;
