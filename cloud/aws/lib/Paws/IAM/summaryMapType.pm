package Paws::IAM::summaryMapType {
  use Moose;
  with 'Paws::API::MapParser';

  use MooseX::ClassAttribute;
  class_has xml_keys =>(is => 'ro', default => 'key');
  class_has xml_values =>(is => 'ro', default => 'value');

  has AccessKeysPerUserQuota => (is => 'ro', isa => 'Int');
  has AccountAccessKeysPresent => (is => 'ro', isa => 'Int');
  has AccountMFAEnabled => (is => 'ro', isa => 'Int');
  has AccountSigningCertificatesPresent => (is => 'ro', isa => 'Int');
  has AttachedPoliciesPerGroupQuota => (is => 'ro', isa => 'Int');
  has AttachedPoliciesPerRoleQuota => (is => 'ro', isa => 'Int');
  has AttachedPoliciesPerUserQuota => (is => 'ro', isa => 'Int');
  has GroupPolicySizeQuota => (is => 'ro', isa => 'Int');
  has Groups => (is => 'ro', isa => 'Int');
  has GroupsPerUserQuota => (is => 'ro', isa => 'Int');
  has GroupsQuota => (is => 'ro', isa => 'Int');
  has MFADevices => (is => 'ro', isa => 'Int');
  has MFADevicesInUse => (is => 'ro', isa => 'Int');
  has Policies => (is => 'ro', isa => 'Int');
  has PoliciesQuota => (is => 'ro', isa => 'Int');
  has PolicySizeQuota => (is => 'ro', isa => 'Int');
  has PolicyVersionsInUse => (is => 'ro', isa => 'Int');
  has PolicyVersionsInUseQuota => (is => 'ro', isa => 'Int');
  has ServerCertificates => (is => 'ro', isa => 'Int');
  has ServerCertificatesQuota => (is => 'ro', isa => 'Int');
  has SigningCertificatesPerUserQuota => (is => 'ro', isa => 'Int');
  has UserPolicySizeQuota => (is => 'ro', isa => 'Int');
  has Users => (is => 'ro', isa => 'Int');
  has UsersQuota => (is => 'ro', isa => 'Int');
  has VersionsPerPolicyQuota => (is => 'ro', isa => 'Int');
}
1
