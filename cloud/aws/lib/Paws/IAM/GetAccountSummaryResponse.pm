
package Paws::IAM::GetAccountSummaryResponse {
  use Moose;
  has SummaryMap => (is => 'ro', isa => 'Paws::IAM::summaryMapType');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::GetAccountSummaryResponse

=head1 ATTRIBUTES

=head2 SummaryMap => Paws::IAM::summaryMapType

  

A set of key value pairs containing information about IAM entity usage
and IAM quotas.

C<SummaryMap> contains the following keys:

=over

=item *

B<AccessKeysPerUserQuota>

The maximum number of active access keys allowed for each IAM user.

=item *

B<AccountAccessKeysPresent>

This value is 1 if the AWS account (root) has an access key, otherwise
it is 0.

=item *

B<AccountMFAEnabled>

This value is 1 if the AWS account (root) has an MFA device assigned,
otherwise it is 0.

=item *

B<AccountSigningCertificatesPresent>

This value is 1 if the AWS account (root) has a signing certificate,
otherwise it is 0.

=item *

B<AssumeRolePolicySizeQuota>

The maximum allowed size for assume role policy documents (trust
policies), in non-whitespace characters.

=item *

B<AttachedPoliciesPerGroupQuota>

The maximum number of managed policies that can be attached to an IAM
group.

=item *

B<AttachedPoliciesPerRoleQuota>

The maximum number of managed policies that can be attached to an IAM
role.

=item *

B<AttachedPoliciesPerUserQuota>

The maximum number of managed policies that can be attached to an IAM
user.

=item *

B<GroupPolicySizeQuota>

The maximum allowed size for the aggregate of all inline policies
embedded in an IAM group, in non-whitespace characters.

=item *

B<Groups>

The number of IAM groups in the AWS account.

=item *

B<GroupsPerUserQuota>

The maximum number of IAM groups each IAM user can belong to.

=item *

B<GroupsQuota>

The maximum number of IAM groups allowed in the AWS account.

=item *

B<InstanceProfiles>

The number of instance profiles in the AWS account.

=item *

B<InstanceProfilesQuota>

The maximum number of instance profiles allowed in the AWS account.

=item *

B<MFADevices>

The number of MFA devices in the AWS account, including those assigned
and unassigned.

=item *

B<MFADevicesInUse>

The number of MFA devices that have been assigned to an IAM user or to
the AWS account (root).

=item *

B<Policies>

The number of customer managed policies in the AWS account.

=item *

B<PoliciesQuota>

The maximum number of customer managed policies allowed in the AWS
account.

=item *

B<PolicySizeQuota>

The maximum allowed size of a customer managed policy, in
non-whitespace characters.

=item *

B<PolicyVersionsInUse>

The number of managed policies that are attached to IAM users, groups,
or roles in the AWS account.

=item *

B<PolicyVersionsInUseQuota>

The maximum number of managed policies that can be attached to IAM
users, groups, or roles in the AWS account.

=item *

B<Providers>

The number of identity providers in the AWS account.

=item *

B<RolePolicySizeQuota>

The maximum allowed size for the aggregate of all inline policies
(access policies, not the trust policy) embedded in an IAM role, in
non-whitespace characters.

=item *

B<Roles>

The number of IAM roles in the AWS account.

=item *

B<RolesQuota>

The maximum number of IAM roles allowed in the AWS account.

=item *

B<ServerCertificates>

The number of server certificates in the AWS account.

=item *

B<ServerCertificatesQuota>

The maximum number of server certificates allowed in the AWS account.

=item *

B<SigningCertificatesPerUserQuota>

The maximum number of X.509 signing certificates allowed for each IAM
user.

=item *

B<UserPolicySizeQuota>

The maximum allowed size for the aggregate of all inline policies
embedded in an IAM user, in non-whitespace characters.

=item *

B<Users>

The number of IAM users in the AWS account.

=item *

B<UsersQuota>

The maximum number of IAM users allowed in the AWS account.

=item *

B<VersionsPerPolicyQuota>

The maximum number of policy versions allowed for each managed policy.

=back











=cut

