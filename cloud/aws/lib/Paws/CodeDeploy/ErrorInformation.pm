package Paws::CodeDeploy::ErrorInformation {
  use Moose;
  has code => (is => 'ro', isa => 'Str');
  has message => (is => 'ro', isa => 'Str');
}
1;
