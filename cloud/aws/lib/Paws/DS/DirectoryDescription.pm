package Paws::DS::DirectoryDescription {
  use Moose;
  has AccessUrl => (is => 'ro', isa => 'Str');
  has Alias => (is => 'ro', isa => 'Str');
  has ConnectSettings => (is => 'ro', isa => 'Paws::DS::DirectoryConnectSettingsDescription');
  has Description => (is => 'ro', isa => 'Str');
  has DirectoryId => (is => 'ro', isa => 'Str');
  has DnsIpAddrs => (is => 'ro', isa => 'ArrayRef[Str]');
  has LaunchTime => (is => 'ro', isa => 'Str');
  has Name => (is => 'ro', isa => 'Str');
  has RadiusSettings => (is => 'ro', isa => 'Paws::DS::RadiusSettings');
  has RadiusStatus => (is => 'ro', isa => 'Str');
  has ShortName => (is => 'ro', isa => 'Str');
  has Size => (is => 'ro', isa => 'Str');
  has SsoEnabled => (is => 'ro', isa => 'Bool');
  has Stage => (is => 'ro', isa => 'Str');
  has StageLastUpdatedDateTime => (is => 'ro', isa => 'Str');
  has StageReason => (is => 'ro', isa => 'Str');
  has Type => (is => 'ro', isa => 'Str');
  has VpcSettings => (is => 'ro', isa => 'Paws::DS::DirectoryVpcSettingsDescription');
}
1;
