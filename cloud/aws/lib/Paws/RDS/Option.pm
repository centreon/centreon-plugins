package Paws::RDS::Option {
  use Moose;
  has DBSecurityGroupMemberships => (is => 'ro', isa => 'ArrayRef[Paws::RDS::DBSecurityGroupMembership]');
  has OptionDescription => (is => 'ro', isa => 'Str');
  has OptionName => (is => 'ro', isa => 'Str');
  has OptionSettings => (is => 'ro', isa => 'ArrayRef[Paws::RDS::OptionSetting]');
  has Permanent => (is => 'ro', isa => 'Bool');
  has Persistent => (is => 'ro', isa => 'Bool');
  has Port => (is => 'ro', isa => 'Int');
  has VpcSecurityGroupMemberships => (is => 'ro', isa => 'ArrayRef[Paws::RDS::VpcSecurityGroupMembership]');
}
1;
