package Paws::OpsWorks::TemporaryCredential {
  use Moose;
  has InstanceId => (is => 'ro', isa => 'Str');
  has Password => (is => 'ro', isa => 'Str');
  has Username => (is => 'ro', isa => 'Str');
  has ValidForInMinutes => (is => 'ro', isa => 'Int');
}
1;
