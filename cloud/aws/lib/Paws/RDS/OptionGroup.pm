package Paws::RDS::OptionGroup {
  use Moose;
  has AllowsVpcAndNonVpcInstanceMemberships => (is => 'ro', isa => 'Bool');
  has EngineName => (is => 'ro', isa => 'Str');
  has MajorEngineVersion => (is => 'ro', isa => 'Str');
  has OptionGroupDescription => (is => 'ro', isa => 'Str');
  has OptionGroupName => (is => 'ro', isa => 'Str');
  has Options => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Option]');
  has VpcId => (is => 'ro', isa => 'Str');
}
1;
