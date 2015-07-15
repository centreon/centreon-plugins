package Paws::CloudFormation::TemplateParameter {
  use Moose;
  has DefaultValue => (is => 'ro', isa => 'Str');
  has Description => (is => 'ro', isa => 'Str');
  has NoEcho => (is => 'ro', isa => 'Bool');
  has ParameterKey => (is => 'ro', isa => 'Str');
}
1;
