package Paws::CodeDeploy::Diagnostics {
  use Moose;
  has errorCode => (is => 'ro', isa => 'Str');
  has logTail => (is => 'ro', isa => 'Str');
  has message => (is => 'ro', isa => 'Str');
  has scriptName => (is => 'ro', isa => 'Str');
}
1;
