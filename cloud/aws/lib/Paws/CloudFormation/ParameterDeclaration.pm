package Paws::CloudFormation::ParameterDeclaration {
  use Moose;
  has DefaultValue => (is => 'ro', isa => 'Str');
  has Description => (is => 'ro', isa => 'Str');
  has NoEcho => (is => 'ro', isa => 'Bool');
  has ParameterConstraints => (is => 'ro', isa => 'Paws::CloudFormation::ParameterConstraints');
  has ParameterKey => (is => 'ro', isa => 'Str');
  has ParameterType => (is => 'ro', isa => 'Str');
}
1;
