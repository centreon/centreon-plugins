package Paws::ElasticBeanstalk::ConfigurationOptionDescription {
  use Moose;
  has ChangeSeverity => (is => 'ro', isa => 'Str');
  has DefaultValue => (is => 'ro', isa => 'Str');
  has MaxLength => (is => 'ro', isa => 'Int');
  has MaxValue => (is => 'ro', isa => 'Int');
  has MinValue => (is => 'ro', isa => 'Int');
  has Name => (is => 'ro', isa => 'Str');
  has Namespace => (is => 'ro', isa => 'Str');
  has Regex => (is => 'ro', isa => 'Paws::ElasticBeanstalk::OptionRestrictionRegex');
  has UserDefined => (is => 'ro', isa => 'Bool');
  has ValueOptions => (is => 'ro', isa => 'ArrayRef[Str]');
  has ValueType => (is => 'ro', isa => 'Str');
}
1;
