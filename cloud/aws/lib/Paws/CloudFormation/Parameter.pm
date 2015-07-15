package Paws::CloudFormation::Parameter {
  use Moose;
  has ParameterKey => (is => 'ro', isa => 'Str');
  has ParameterValue => (is => 'ro', isa => 'Str');
  has UsePreviousValue => (is => 'ro', isa => 'Bool');
}
1;
