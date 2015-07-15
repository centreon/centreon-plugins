package Paws::RDS::OptionGroupOptionSetting {
  use Moose;
  has AllowedValues => (is => 'ro', isa => 'Str');
  has ApplyType => (is => 'ro', isa => 'Str');
  has DefaultValue => (is => 'ro', isa => 'Str');
  has IsModifiable => (is => 'ro', isa => 'Bool');
  has SettingDescription => (is => 'ro', isa => 'Str');
  has SettingName => (is => 'ro', isa => 'Str');
}
1;
