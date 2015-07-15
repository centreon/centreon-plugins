package Paws::CloudFormation::ParameterConstraints {
  use Moose;
  has AllowedValues => (is => 'ro', isa => 'ArrayRef[Str]');
}
1;
