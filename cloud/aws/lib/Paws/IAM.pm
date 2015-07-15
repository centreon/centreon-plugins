package Paws::IAM {
  use Moose;
  sub service { 'iam' }
  sub version { '2010-05-08' }
  sub flattened_arrays { 0 }

  with 'Paws::API::Caller', 'Paws::API::RegionalEndpointCaller', 'Paws::Net::V4Signature', 'Paws::Net::QueryCaller', 'Paws::Net::XMLResponse';

  
  sub AddClientIDToOpenIDConnectProvider {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::AddClientIDToOpenIDConnectProvider', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AddRoleToInstanceProfile {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::AddRoleToInstanceProfile', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AddUserToGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::AddUserToGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AttachGroupPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::AttachGroupPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AttachRolePolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::AttachRolePolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AttachUserPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::AttachUserPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ChangePassword {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ChangePassword', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateAccessKey {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::CreateAccessKey', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateAccountAlias {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::CreateAccountAlias', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::CreateGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateInstanceProfile {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::CreateInstanceProfile', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateLoginProfile {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::CreateLoginProfile', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateOpenIDConnectProvider {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::CreateOpenIDConnectProvider', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreatePolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::CreatePolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreatePolicyVersion {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::CreatePolicyVersion', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateRole {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::CreateRole', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateSAMLProvider {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::CreateSAMLProvider', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateUser {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::CreateUser', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateVirtualMFADevice {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::CreateVirtualMFADevice', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeactivateMFADevice {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeactivateMFADevice', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteAccessKey {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteAccessKey', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteAccountAlias {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteAccountAlias', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteAccountPasswordPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteAccountPasswordPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteGroupPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteGroupPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteInstanceProfile {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteInstanceProfile', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteLoginProfile {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteLoginProfile', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteOpenIDConnectProvider {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteOpenIDConnectProvider', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeletePolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeletePolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeletePolicyVersion {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeletePolicyVersion', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteRole {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteRole', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteRolePolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteRolePolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteSAMLProvider {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteSAMLProvider', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteServerCertificate {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteServerCertificate', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteSigningCertificate {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteSigningCertificate', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteUser {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteUser', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteUserPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteUserPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteVirtualMFADevice {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DeleteVirtualMFADevice', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DetachGroupPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DetachGroupPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DetachRolePolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DetachRolePolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DetachUserPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::DetachUserPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub EnableMFADevice {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::EnableMFADevice', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GenerateCredentialReport {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GenerateCredentialReport', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetAccessKeyLastUsed {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetAccessKeyLastUsed', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetAccountAuthorizationDetails {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetAccountAuthorizationDetails', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetAccountPasswordPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetAccountPasswordPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetAccountSummary {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetAccountSummary', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetCredentialReport {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetCredentialReport', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetGroupPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetGroupPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetInstanceProfile {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetInstanceProfile', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetLoginProfile {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetLoginProfile', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetOpenIDConnectProvider {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetOpenIDConnectProvider', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetPolicyVersion {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetPolicyVersion', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetRole {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetRole', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetRolePolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetRolePolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetSAMLProvider {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetSAMLProvider', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetServerCertificate {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetServerCertificate', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetUser {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetUser', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetUserPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::GetUserPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListAccessKeys {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListAccessKeys', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListAccountAliases {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListAccountAliases', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListAttachedGroupPolicies {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListAttachedGroupPolicies', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListAttachedRolePolicies {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListAttachedRolePolicies', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListAttachedUserPolicies {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListAttachedUserPolicies', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListEntitiesForPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListEntitiesForPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListGroupPolicies {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListGroupPolicies', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListGroupsForUser {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListGroupsForUser', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListInstanceProfiles {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListInstanceProfiles', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListInstanceProfilesForRole {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListInstanceProfilesForRole', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListMFADevices {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListMFADevices', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListOpenIDConnectProviders {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListOpenIDConnectProviders', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListPolicies {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListPolicies', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListPolicyVersions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListPolicyVersions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListRolePolicies {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListRolePolicies', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListRoles {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListRoles', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListSAMLProviders {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListSAMLProviders', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListServerCertificates {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListServerCertificates', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListSigningCertificates {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListSigningCertificates', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListUserPolicies {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListUserPolicies', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListUsers {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListUsers', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListVirtualMFADevices {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ListVirtualMFADevices', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PutGroupPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::PutGroupPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PutRolePolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::PutRolePolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PutUserPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::PutUserPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RemoveClientIDFromOpenIDConnectProvider {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::RemoveClientIDFromOpenIDConnectProvider', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RemoveRoleFromInstanceProfile {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::RemoveRoleFromInstanceProfile', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RemoveUserFromGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::RemoveUserFromGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ResyncMFADevice {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::ResyncMFADevice', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SetDefaultPolicyVersion {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::SetDefaultPolicyVersion', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateAccessKey {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::UpdateAccessKey', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateAccountPasswordPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::UpdateAccountPasswordPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateAssumeRolePolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::UpdateAssumeRolePolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::UpdateGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateLoginProfile {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::UpdateLoginProfile', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateOpenIDConnectProviderThumbprint {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::UpdateOpenIDConnectProviderThumbprint', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateSAMLProvider {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::UpdateSAMLProvider', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateServerCertificate {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::UpdateServerCertificate', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateSigningCertificate {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::UpdateSigningCertificate', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateUser {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::UpdateUser', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UploadServerCertificate {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::UploadServerCertificate', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UploadSigningCertificate {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::IAM::UploadSigningCertificate', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM - Perl Interface to AWS AWS Identity and Access Management

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('IAM')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



AWS Identity and Access Management

AWS Identity and Access Management (IAM) is a web service that you can
use to manage users and user permissions under your AWS account. This
guide provides descriptions of IAM actions that you can call
programmatically. For general information about IAM, see AWS Identity
and Access Management (IAM). For the user guide for IAM, see Using IAM.

AWS provides SDKs that consist of libraries and sample code for various
programming languages and platforms (Java, Ruby, .NET, iOS, Android,
etc.). The SDKs provide a convenient way to create programmatic access
to IAM and AWS. For example, the SDKs take care of tasks such as
cryptographically signing requests (see below), managing errors, and
retrying requests automatically. For information about the AWS SDKs,
including how to download and install them, see the Tools for Amazon
Web Services page.

We recommend that you use the AWS SDKs to make programmatic API calls
to IAM. However, you can also use the IAM Query API to make direct
calls to the IAM web service. To learn more about the IAM Query API,
see Making Query Requests in the I<Using IAM> guide. IAM supports GET
and POST requests for all actions. That is, the API does not require
you to use GET for some actions and POST for others. However, GET
requests are subject to the limitation size of a URL. Therefore, for
operations that require larger sizes, use a POST request.

B<Signing Requests>

Requests must be signed using an access key ID and a secret access key.
We strongly recommend that you do not use your AWS account access key
ID and secret access key for everyday work with IAM. You can use the
access key ID and secret access key for an IAM user or you can use the
AWS Security Token Service to generate temporary security credentials
and use those to sign requests.

To sign requests, we recommend that you use Signature Version 4. If you
have an existing application that uses Signature Version 2, you do not
have to update it to use Signature Version 4. However, some operations
now require Signature Version 4. The documentation for operations that
require version 4 indicate this requirement.

B<Additional Resources>

For more information, see the following:

=over

=item * AWS Security Credentials. This topic provides general
information about the types of credentials used for accessing AWS.

=item * IAM Best Practices. This topic presents a list of suggestions
for using the IAM service to help secure your AWS resources.

=item * AWS Security Token Service. This guide describes how to create
and use temporary security credentials.

=item * Signing AWS API Requests. This set of topics walk you through
the process of signing a request using an access key ID and secret
access key.

=back










=head1 METHODS

=head2 AddClientIDToOpenIDConnectProvider(ClientID => Str, OpenIDConnectProviderArn => Str)

Each argument is described in detail in: L<Paws::IAM::AddClientIDToOpenIDConnectProvider>

Returns: nothing

  

Adds a new client ID (also known as audience) to the list of client IDs
already registered for the specified IAM OpenID Connect provider.

This action is idempotent; it does not fail or return an error if you
add an existing client ID to the provider.











=head2 AddRoleToInstanceProfile(InstanceProfileName => Str, RoleName => Str)

Each argument is described in detail in: L<Paws::IAM::AddRoleToInstanceProfile>

Returns: nothing

  

Adds the specified role to the specified instance profile. For more
information about roles, go to Working with Roles. For more information
about instance profiles, go to About Instance Profiles.











=head2 AddUserToGroup(GroupName => Str, UserName => Str)

Each argument is described in detail in: L<Paws::IAM::AddUserToGroup>

Returns: nothing

  

Adds the specified user to the specified group.











=head2 AttachGroupPolicy(GroupName => Str, PolicyArn => Str)

Each argument is described in detail in: L<Paws::IAM::AttachGroupPolicy>

Returns: nothing

  

Attaches the specified managed policy to the specified group.

You use this API to attach a managed policy to a group. To embed an
inline policy in a group, use PutGroupPolicy.

For more information about policies, refer to Managed Policies and
Inline Policies in the I<Using IAM> guide.











=head2 AttachRolePolicy(PolicyArn => Str, RoleName => Str)

Each argument is described in detail in: L<Paws::IAM::AttachRolePolicy>

Returns: nothing

  

Attaches the specified managed policy to the specified role.

When you attach a managed policy to a role, the managed policy is used
as the role's access (permissions) policy. You cannot use a managed
policy as the role's trust policy. The role's trust policy is created
at the same time as the role, using CreateRole. You can update a role's
trust policy using UpdateAssumeRolePolicy.

Use this API to attach a managed policy to a role. To embed an inline
policy in a role, use PutRolePolicy. For more information about
policies, refer to Managed Policies and Inline Policies in the I<Using
IAM> guide.











=head2 AttachUserPolicy(PolicyArn => Str, UserName => Str)

Each argument is described in detail in: L<Paws::IAM::AttachUserPolicy>

Returns: nothing

  

Attaches the specified managed policy to the specified user.

You use this API to attach a managed policy to a user. To embed an
inline policy in a user, use PutUserPolicy.

For more information about policies, refer to Managed Policies and
Inline Policies in the I<Using IAM> guide.











=head2 ChangePassword(NewPassword => Str, OldPassword => Str)

Each argument is described in detail in: L<Paws::IAM::ChangePassword>

Returns: nothing

  

Changes the password of the IAM user who is calling this action. The
root account password is not affected by this action.

To change the password for a different user, see UpdateLoginProfile.
For more information about modifying passwords, see Managing Passwords
in the I<Using IAM> guide.











=head2 CreateAccessKey([UserName => Str])

Each argument is described in detail in: L<Paws::IAM::CreateAccessKey>

Returns: a L<Paws::IAM::CreateAccessKeyResponse> instance

  

Creates a new AWS secret access key and corresponding AWS access key ID
for the specified user. The default status for new keys is C<Active>.

If you do not specify a user name, IAM determines the user name
implicitly based on the AWS access key ID signing the request. Because
this action works for access keys under the AWS account, you can use
this action to manage root credentials even if the AWS account has no
associated users.

For information about limits on the number of keys you can create, see
Limitations on IAM Entities in the I<Using IAM> guide.

To ensure the security of your AWS account, the secret access key is
accessible only during key and user creation. You must save the key
(for example, in a text file) if you want to be able to access it
again. If a secret key is lost, you can delete the access keys for the
associated user and then create new keys.











=head2 CreateAccountAlias(AccountAlias => Str)

Each argument is described in detail in: L<Paws::IAM::CreateAccountAlias>

Returns: nothing

  

Creates an alias for your AWS account. For information about using an
AWS account alias, see Using an Alias for Your AWS Account ID in the
I<Using IAM> guide.











=head2 CreateGroup(GroupName => Str, [Path => Str])

Each argument is described in detail in: L<Paws::IAM::CreateGroup>

Returns: a L<Paws::IAM::CreateGroupResponse> instance

  

Creates a new group.

For information about the number of groups you can create, see
Limitations on IAM Entities in the I<Using IAM> guide.











=head2 CreateInstanceProfile(InstanceProfileName => Str, [Path => Str])

Each argument is described in detail in: L<Paws::IAM::CreateInstanceProfile>

Returns: a L<Paws::IAM::CreateInstanceProfileResponse> instance

  

Creates a new instance profile. For information about instance
profiles, go to About Instance Profiles.

For information about the number of instance profiles you can create,
see Limitations on IAM Entities in the I<Using IAM> guide.











=head2 CreateLoginProfile(Password => Str, UserName => Str, [PasswordResetRequired => Bool])

Each argument is described in detail in: L<Paws::IAM::CreateLoginProfile>

Returns: a L<Paws::IAM::CreateLoginProfileResponse> instance

  

Creates a password for the specified user, giving the user the ability
to access AWS services through the AWS Management Console. For more
information about managing passwords, see Managing Passwords in the
I<Using IAM> guide.











=head2 CreateOpenIDConnectProvider(ThumbprintList => ArrayRef[Str], Url => Str, [ClientIDList => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::IAM::CreateOpenIDConnectProvider>

Returns: a L<Paws::IAM::CreateOpenIDConnectProviderResponse> instance

  

Creates an IAM entity to describe an identity provider (IdP) that
supports OpenID Connect (OIDC).

The OIDC provider that you create with this operation can be used as a
principal in a role's trust policy to establish a trust relationship
between AWS and the OIDC provider.

When you create the IAM OIDC provider, you specify the URL of the OIDC
identity provider (IdP) to trust, a list of client IDs (also known as
audiences) that identify the application or applications that are
allowed to authenticate using the OIDC provider, and a list of
thumbprints of the server certificate(s) that the IdP uses. You get all
of this information from the OIDC IdP that you want to use for access
to AWS.

Because trust for the OIDC provider is ultimately derived from the IAM
provider that this action creates, it is a best practice to limit
access to the CreateOpenIDConnectProvider action to highly-privileged
users.











=head2 CreatePolicy(PolicyDocument => Str, PolicyName => Str, [Description => Str, Path => Str])

Each argument is described in detail in: L<Paws::IAM::CreatePolicy>

Returns: a L<Paws::IAM::CreatePolicyResponse> instance

  

Creates a new managed policy for your AWS account.

This operation creates a policy version with a version identifier of
C<v1> and sets v1 as the policy's default version. For more information
about policy versions, see Versioning for Managed Policies in the
I<Using IAM> guide.

For more information about managed policies in general, refer to
Managed Policies and Inline Policies in the I<Using IAM> guide.











=head2 CreatePolicyVersion(PolicyArn => Str, PolicyDocument => Str, [SetAsDefault => Bool])

Each argument is described in detail in: L<Paws::IAM::CreatePolicyVersion>

Returns: a L<Paws::IAM::CreatePolicyVersionResponse> instance

  

Creates a new version of the specified managed policy. To update a
managed policy, you create a new policy version. A managed policy can
have up to five versions. If the policy has five versions, you must
delete an existing version using DeletePolicyVersion before you create
a new version.

Optionally, you can set the new version as the policy's default
version. The default version is the operative version; that is, the
version that is in effect for the IAM users, groups, and roles that the
policy is attached to.

For more information about managed policy versions, see Versioning for
Managed Policies in the I<Using IAM> guide.











=head2 CreateRole(AssumeRolePolicyDocument => Str, RoleName => Str, [Path => Str])

Each argument is described in detail in: L<Paws::IAM::CreateRole>

Returns: a L<Paws::IAM::CreateRoleResponse> instance

  

Creates a new role for your AWS account. For more information about
roles, go to Working with Roles. For information about limitations on
role names and the number of roles you can create, go to Limitations on
IAM Entities in the I<Using IAM> guide.

The policy in the following example grants permission to an EC2
instance to assume the role.











=head2 CreateSAMLProvider(Name => Str, SAMLMetadataDocument => Str)

Each argument is described in detail in: L<Paws::IAM::CreateSAMLProvider>

Returns: a L<Paws::IAM::CreateSAMLProviderResponse> instance

  

Creates an IAM entity to describe an identity provider (IdP) that
supports SAML 2.0.

The SAML provider that you create with this operation can be used as a
principal in a role's trust policy to establish a trust relationship
between AWS and a SAML identity provider. You can create an IAM role
that supports Web-based single sign-on (SSO) to the AWS Management
Console or one that supports API access to AWS.

When you create the SAML provider, you upload an a SAML metadata
document that you get from your IdP and that includes the issuer's
name, expiration information, and keys that can be used to validate the
SAML authentication response (assertions) that are received from the
IdP. You must generate the metadata document using the identity
management software that is used as your organization's IdP.

This operation requires Signature Version 4.

For more information, see Giving Console Access Using SAML and Creating
Temporary Security Credentials for SAML Federation in the I<Using
Temporary Credentials> guide.











=head2 CreateUser(UserName => Str, [Path => Str])

Each argument is described in detail in: L<Paws::IAM::CreateUser>

Returns: a L<Paws::IAM::CreateUserResponse> instance

  

Creates a new user for your AWS account.

For information about limitations on the number of users you can
create, see Limitations on IAM Entities in the I<Using IAM> guide.











=head2 CreateVirtualMFADevice(VirtualMFADeviceName => Str, [Path => Str])

Each argument is described in detail in: L<Paws::IAM::CreateVirtualMFADevice>

Returns: a L<Paws::IAM::CreateVirtualMFADeviceResponse> instance

  

Creates a new virtual MFA device for the AWS account. After creating
the virtual MFA, use EnableMFADevice to attach the MFA device to an IAM
user. For more information about creating and working with virtual MFA
devices, go to Using a Virtual MFA Device in the I<Using IAM> guide.

For information about limits on the number of MFA devices you can
create, see Limitations on Entities in the I<Using IAM> guide.

The seed information contained in the QR code and the Base32 string
should be treated like any other secret access information, such as
your AWS access keys or your passwords. After you provision your
virtual device, you should ensure that the information is destroyed
following secure procedures.











=head2 DeactivateMFADevice(SerialNumber => Str, UserName => Str)

Each argument is described in detail in: L<Paws::IAM::DeactivateMFADevice>

Returns: nothing

  

Deactivates the specified MFA device and removes it from association
with the user name for which it was originally enabled.

For more information about creating and working with virtual MFA
devices, go to Using a Virtual MFA Device in the I<Using IAM> guide.











=head2 DeleteAccessKey(AccessKeyId => Str, [UserName => Str])

Each argument is described in detail in: L<Paws::IAM::DeleteAccessKey>

Returns: nothing

  

Deletes the access key associated with the specified user.

If you do not specify a user name, IAM determines the user name
implicitly based on the AWS access key ID signing the request. Because
this action works for access keys under the AWS account, you can use
this action to manage root credentials even if the AWS account has no
associated users.











=head2 DeleteAccountAlias(AccountAlias => Str)

Each argument is described in detail in: L<Paws::IAM::DeleteAccountAlias>

Returns: nothing

  

Deletes the specified AWS account alias. For information about using an
AWS account alias, see Using an Alias for Your AWS Account ID in the
I<Using IAM> guide.











=head2 DeleteAccountPasswordPolicy( => )

Each argument is described in detail in: L<Paws::IAM::DeleteAccountPasswordPolicy>

Returns: nothing

  

Deletes the password policy for the AWS account.











=head2 DeleteGroup(GroupName => Str)

Each argument is described in detail in: L<Paws::IAM::DeleteGroup>

Returns: nothing

  

Deletes the specified group. The group must not contain any users or
have any attached policies.











=head2 DeleteGroupPolicy(GroupName => Str, PolicyName => Str)

Each argument is described in detail in: L<Paws::IAM::DeleteGroupPolicy>

Returns: nothing

  

Deletes the specified inline policy that is embedded in the specified
group.

A group can also have managed policies attached to it. To detach a
managed policy from a group, use DetachGroupPolicy. For more
information about policies, refer to Managed Policies and Inline
Policies in the I<Using IAM> guide.











=head2 DeleteInstanceProfile(InstanceProfileName => Str)

Each argument is described in detail in: L<Paws::IAM::DeleteInstanceProfile>

Returns: nothing

  

Deletes the specified instance profile. The instance profile must not
have an associated role.

Make sure you do not have any Amazon EC2 instances running with the
instance profile you are about to delete. Deleting a role or instance
profile that is associated with a running instance will break any
applications running on the instance.

For more information about instance profiles, go to About Instance
Profiles.











=head2 DeleteLoginProfile(UserName => Str)

Each argument is described in detail in: L<Paws::IAM::DeleteLoginProfile>

Returns: nothing

  

Deletes the password for the specified user, which terminates the
user's ability to access AWS services through the AWS Management
Console.

Deleting a user's password does not prevent a user from accessing IAM
through the command line interface or the API. To prevent all user
access you must also either make the access key inactive or delete it.
For more information about making keys inactive or deleting them, see
UpdateAccessKey and DeleteAccessKey.











=head2 DeleteOpenIDConnectProvider(OpenIDConnectProviderArn => Str)

Each argument is described in detail in: L<Paws::IAM::DeleteOpenIDConnectProvider>

Returns: nothing

  

Deletes an IAM OpenID Connect identity provider.

Deleting an OIDC provider does not update any roles that reference the
provider as a principal in their trust policies. Any attempt to assume
a role that references a provider that has been deleted will fail.

This action is idempotent; it does not fail or return an error if you
call the action for a provider that was already deleted.











=head2 DeletePolicy(PolicyArn => Str)

Each argument is described in detail in: L<Paws::IAM::DeletePolicy>

Returns: nothing

  

Deletes the specified managed policy.

Before you can delete a managed policy, you must detach the policy from
all users, groups, and roles that it is attached to, and you must
delete all of the policy's versions. The following steps describe the
process for deleting a managed policy:

=over

=item 1. Detach the policy from all users, groups, and roles that the
policy is attached to, using the DetachUserPolicy, DetachGroupPolicy,
or DetachRolePolicy APIs. To list all the users, groups, and roles that
a policy is attached to, use ListEntitiesForPolicy.

=item 2. Delete all versions of the policy using DeletePolicyVersion.
To list the policy's versions, use ListPolicyVersions. You cannot use
DeletePolicyVersion to delete the version that is marked as the default
version. You delete the policy's default version in the next step of
the process.

=item 3. Delete the policy (this automatically deletes the policy's
default version) using this API.

=back

For information about managed policies, refer to Managed Policies and
Inline Policies in the I<Using IAM> guide.











=head2 DeletePolicyVersion(PolicyArn => Str, VersionId => Str)

Each argument is described in detail in: L<Paws::IAM::DeletePolicyVersion>

Returns: nothing

  

Deletes the specified version of the specified managed policy.

You cannot delete the default version of a policy using this API. To
delete the default version of a policy, use DeletePolicy. To find out
which version of a policy is marked as the default version, use
ListPolicyVersions.

For information about versions for managed policies, refer to
Versioning for Managed Policies in the I<Using IAM> guide.











=head2 DeleteRole(RoleName => Str)

Each argument is described in detail in: L<Paws::IAM::DeleteRole>

Returns: nothing

  

Deletes the specified role. The role must not have any policies
attached. For more information about roles, go to Working with Roles.

Make sure you do not have any Amazon EC2 instances running with the
role you are about to delete. Deleting a role or instance profile that
is associated with a running instance will break any applications
running on the instance.











=head2 DeleteRolePolicy(PolicyName => Str, RoleName => Str)

Each argument is described in detail in: L<Paws::IAM::DeleteRolePolicy>

Returns: nothing

  

Deletes the specified inline policy that is embedded in the specified
role.

A role can also have managed policies attached to it. To detach a
managed policy from a role, use DetachRolePolicy. For more information
about policies, refer to Managed Policies and Inline Policies in the
I<Using IAM> guide.











=head2 DeleteSAMLProvider(SAMLProviderArn => Str)

Each argument is described in detail in: L<Paws::IAM::DeleteSAMLProvider>

Returns: nothing

  

Deletes a SAML provider.

Deleting the provider does not update any roles that reference the SAML
provider as a principal in their trust policies. Any attempt to assume
a role that references a SAML provider that has been deleted will fail.

This operation requires Signature Version 4.











=head2 DeleteServerCertificate(ServerCertificateName => Str)

Each argument is described in detail in: L<Paws::IAM::DeleteServerCertificate>

Returns: nothing

  

Deletes the specified server certificate.

If you are using a server certificate with Elastic Load Balancing,
deleting the certificate could have implications for your application.
If Elastic Load Balancing doesn't detect the deletion of bound
certificates, it may continue to use the certificates. This could cause
Elastic Load Balancing to stop accepting traffic. We recommend that you
remove the reference to the certificate from Elastic Load Balancing
before using this command to delete the certificate. For more
information, go to DeleteLoadBalancerListeners in the I<Elastic Load
Balancing API Reference>.











=head2 DeleteSigningCertificate(CertificateId => Str, [UserName => Str])

Each argument is described in detail in: L<Paws::IAM::DeleteSigningCertificate>

Returns: nothing

  

Deletes the specified signing certificate associated with the specified
user.

If you do not specify a user name, IAM determines the user name
implicitly based on the AWS access key ID signing the request. Because
this action works for access keys under the AWS account, you can use
this action to manage root credentials even if the AWS account has no
associated users.











=head2 DeleteUser(UserName => Str)

Each argument is described in detail in: L<Paws::IAM::DeleteUser>

Returns: nothing

  

Deletes the specified user. The user must not belong to any groups,
have any keys or signing certificates, or have any attached policies.











=head2 DeleteUserPolicy(PolicyName => Str, UserName => Str)

Each argument is described in detail in: L<Paws::IAM::DeleteUserPolicy>

Returns: nothing

  

Deletes the specified inline policy that is embedded in the specified
user.

A user can also have managed policies attached to it. To detach a
managed policy from a user, use DetachUserPolicy. For more information
about policies, refer to Managed Policies and Inline Policies in the
I<Using IAM> guide.











=head2 DeleteVirtualMFADevice(SerialNumber => Str)

Each argument is described in detail in: L<Paws::IAM::DeleteVirtualMFADevice>

Returns: nothing

  

Deletes a virtual MFA device.

You must deactivate a user's virtual MFA device before you can delete
it. For information about deactivating MFA devices, see
DeactivateMFADevice.











=head2 DetachGroupPolicy(GroupName => Str, PolicyArn => Str)

Each argument is described in detail in: L<Paws::IAM::DetachGroupPolicy>

Returns: nothing

  

Removes the specified managed policy from the specified group.

A group can also have inline policies embedded with it. To delete an
inline policy, use the DeleteGroupPolicy API. For information about
policies, refer to Managed Policies and Inline Policies in the I<Using
IAM> guide.











=head2 DetachRolePolicy(PolicyArn => Str, RoleName => Str)

Each argument is described in detail in: L<Paws::IAM::DetachRolePolicy>

Returns: nothing

  

Removes the specified managed policy from the specified role.

A role can also have inline policies embedded with it. To delete an
inline policy, use the DeleteRolePolicy API. For information about
policies, refer to Managed Policies and Inline Policies in the I<Using
IAM> guide.











=head2 DetachUserPolicy(PolicyArn => Str, UserName => Str)

Each argument is described in detail in: L<Paws::IAM::DetachUserPolicy>

Returns: nothing

  

Removes the specified managed policy from the specified user.

A user can also have inline policies embedded with it. To delete an
inline policy, use the DeleteUserPolicy API. For information about
policies, refer to Managed Policies and Inline Policies in the I<Using
IAM> guide.











=head2 EnableMFADevice(AuthenticationCode1 => Str, AuthenticationCode2 => Str, SerialNumber => Str, UserName => Str)

Each argument is described in detail in: L<Paws::IAM::EnableMFADevice>

Returns: nothing

  

Enables the specified MFA device and associates it with the specified
user name. When enabled, the MFA device is required for every
subsequent login by the user name associated with the device.











=head2 GenerateCredentialReport( => )

Each argument is described in detail in: L<Paws::IAM::GenerateCredentialReport>

Returns: a L<Paws::IAM::GenerateCredentialReportResponse> instance

  

Generates a credential report for the AWS account. For more information
about the credential report, see Getting Credential Reports in the
I<Using IAM> guide.











=head2 GetAccessKeyLastUsed(AccessKeyId => Str)

Each argument is described in detail in: L<Paws::IAM::GetAccessKeyLastUsed>

Returns: a L<Paws::IAM::GetAccessKeyLastUsedResponse> instance

  

Retrieves information about when the specified access key was last
used. The information includes the date and time of last use, along
with the AWS service and region that were specified in the last request
made with that key.











=head2 GetAccountAuthorizationDetails([Filter => ArrayRef[Str], Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::IAM::GetAccountAuthorizationDetails>

Returns: a L<Paws::IAM::GetAccountAuthorizationDetailsResponse> instance

  

Retrieves information about all IAM users, groups, roles, and policies
in your account, including their relationships to one another. Use this
API to obtain a snapshot of the configuration of IAM permissions
(users, groups, roles, and policies) in your account.

You can optionally filter the results using the C<Filter> parameter.
You can paginate the results using the C<MaxItems> and C<Marker>
parameters.











=head2 GetAccountPasswordPolicy( => )

Each argument is described in detail in: L<Paws::IAM::GetAccountPasswordPolicy>

Returns: a L<Paws::IAM::GetAccountPasswordPolicyResponse> instance

  

Retrieves the password policy for the AWS account. For more information
about using a password policy, go to Managing an IAM Password Policy.











=head2 GetAccountSummary( => )

Each argument is described in detail in: L<Paws::IAM::GetAccountSummary>

Returns: a L<Paws::IAM::GetAccountSummaryResponse> instance

  

Retrieves information about IAM entity usage and IAM quotas in the AWS
account.

For information about limitations on IAM entities, see Limitations on
IAM Entities in the I<Using IAM> guide.











=head2 GetCredentialReport( => )

Each argument is described in detail in: L<Paws::IAM::GetCredentialReport>

Returns: a L<Paws::IAM::GetCredentialReportResponse> instance

  

Retrieves a credential report for the AWS account. For more information
about the credential report, see Getting Credential Reports in the
I<Using IAM> guide.











=head2 GetGroup(GroupName => Str, [Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::IAM::GetGroup>

Returns: a L<Paws::IAM::GetGroupResponse> instance

  

Returns a list of users that are in the specified group. You can
paginate the results using the C<MaxItems> and C<Marker> parameters.











=head2 GetGroupPolicy(GroupName => Str, PolicyName => Str)

Each argument is described in detail in: L<Paws::IAM::GetGroupPolicy>

Returns: a L<Paws::IAM::GetGroupPolicyResponse> instance

  

Retrieves the specified inline policy document that is embedded in the
specified group.

A group can also have managed policies attached to it. To retrieve a
managed policy document that is attached to a group, use GetPolicy to
determine the policy's default version, then use GetPolicyVersion to
retrieve the policy document.

For more information about policies, refer to Managed Policies and
Inline Policies in the I<Using IAM> guide.











=head2 GetInstanceProfile(InstanceProfileName => Str)

Each argument is described in detail in: L<Paws::IAM::GetInstanceProfile>

Returns: a L<Paws::IAM::GetInstanceProfileResponse> instance

  

Retrieves information about the specified instance profile, including
the instance profile's path, GUID, ARN, and role. For more information
about instance profiles, go to About Instance Profiles. For more
information about ARNs, go to ARNs.











=head2 GetLoginProfile(UserName => Str)

Each argument is described in detail in: L<Paws::IAM::GetLoginProfile>

Returns: a L<Paws::IAM::GetLoginProfileResponse> instance

  

Retrieves the user name and password-creation date for the specified
user. If the user has not been assigned a password, the action returns
a 404 (C<NoSuchEntity>) error.











=head2 GetOpenIDConnectProvider(OpenIDConnectProviderArn => Str)

Each argument is described in detail in: L<Paws::IAM::GetOpenIDConnectProvider>

Returns: a L<Paws::IAM::GetOpenIDConnectProviderResponse> instance

  

Returns information about the specified OpenID Connect provider.











=head2 GetPolicy(PolicyArn => Str)

Each argument is described in detail in: L<Paws::IAM::GetPolicy>

Returns: a L<Paws::IAM::GetPolicyResponse> instance

  

Retrieves information about the specified managed policy, including the
policy's default version and the total number of users, groups, and
roles that the policy is attached to. For a list of the specific users,
groups, and roles that the policy is attached to, use the
ListEntitiesForPolicy API. This API returns metadata about the policy.
To retrieve the policy document for a specific version of the policy,
use GetPolicyVersion.

This API retrieves information about managed policies. To retrieve
information about an inline policy that is embedded with a user, group,
or role, use the GetUserPolicy, GetGroupPolicy, or GetRolePolicy API.

For more information about policies, refer to Managed Policies and
Inline Policies in the I<Using IAM> guide.











=head2 GetPolicyVersion(PolicyArn => Str, VersionId => Str)

Each argument is described in detail in: L<Paws::IAM::GetPolicyVersion>

Returns: a L<Paws::IAM::GetPolicyVersionResponse> instance

  

Retrieves information about the specified version of the specified
managed policy, including the policy document.

To list the available versions for a policy, use ListPolicyVersions.

This API retrieves information about managed policies. To retrieve
information about an inline policy that is embedded in a user, group,
or role, use the GetUserPolicy, GetGroupPolicy, or GetRolePolicy API.

For more information about the types of policies, refer to Managed
Policies and Inline Policies in the I<Using IAM> guide.











=head2 GetRole(RoleName => Str)

Each argument is described in detail in: L<Paws::IAM::GetRole>

Returns: a L<Paws::IAM::GetRoleResponse> instance

  

Retrieves information about the specified role, including the role's
path, GUID, ARN, and the policy granting permission to assume the role.
For more information about ARNs, go to ARNs. For more information about
roles, go to Working with Roles.











=head2 GetRolePolicy(PolicyName => Str, RoleName => Str)

Each argument is described in detail in: L<Paws::IAM::GetRolePolicy>

Returns: a L<Paws::IAM::GetRolePolicyResponse> instance

  

Retrieves the specified inline policy document that is embedded with
the specified role.

A role can also have managed policies attached to it. To retrieve a
managed policy document that is attached to a role, use GetPolicy to
determine the policy's default version, then use GetPolicyVersion to
retrieve the policy document.

For more information about policies, refer to Managed Policies and
Inline Policies in the I<Using IAM> guide.

For more information about roles, go to Using Roles to Delegate
Permissions and Federate Identities.











=head2 GetSAMLProvider(SAMLProviderArn => Str)

Each argument is described in detail in: L<Paws::IAM::GetSAMLProvider>

Returns: a L<Paws::IAM::GetSAMLProviderResponse> instance

  

Returns the SAML provider metadocument that was uploaded when the
provider was created or updated.

This operation requires Signature Version 4.











=head2 GetServerCertificate(ServerCertificateName => Str)

Each argument is described in detail in: L<Paws::IAM::GetServerCertificate>

Returns: a L<Paws::IAM::GetServerCertificateResponse> instance

  

Retrieves information about the specified server certificate.











=head2 GetUser([UserName => Str])

Each argument is described in detail in: L<Paws::IAM::GetUser>

Returns: a L<Paws::IAM::GetUserResponse> instance

  

Retrieves information about the specified user, including the user's
creation date, path, unique ID, and ARN.

If you do not specify a user name, IAM determines the user name
implicitly based on the AWS access key ID used to sign the request.











=head2 GetUserPolicy(PolicyName => Str, UserName => Str)

Each argument is described in detail in: L<Paws::IAM::GetUserPolicy>

Returns: a L<Paws::IAM::GetUserPolicyResponse> instance

  

Retrieves the specified inline policy document that is embedded in the
specified user.

A user can also have managed policies attached to it. To retrieve a
managed policy document that is attached to a user, use GetPolicy to
determine the policy's default version, then use GetPolicyVersion to
retrieve the policy document.

For more information about policies, refer to Managed Policies and
Inline Policies in the I<Using IAM> guide.











=head2 ListAccessKeys([Marker => Str, MaxItems => Int, UserName => Str])

Each argument is described in detail in: L<Paws::IAM::ListAccessKeys>

Returns: a L<Paws::IAM::ListAccessKeysResponse> instance

  

Returns information about the access key IDs associated with the
specified user. If there are none, the action returns an empty list.

Although each user is limited to a small number of keys, you can still
paginate the results using the C<MaxItems> and C<Marker> parameters.

If the C<UserName> field is not specified, the UserName is determined
implicitly based on the AWS access key ID used to sign the request.
Because this action works for access keys under the AWS account, you
can use this action to manage root credentials even if the AWS account
has no associated users.

To ensure the security of your AWS account, the secret access key is
accessible only during key and user creation.











=head2 ListAccountAliases([Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::IAM::ListAccountAliases>

Returns: a L<Paws::IAM::ListAccountAliasesResponse> instance

  

Lists the account aliases associated with the account. For information
about using an AWS account alias, see Using an Alias for Your AWS
Account ID in the I<Using IAM> guide.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters.











=head2 ListAttachedGroupPolicies(GroupName => Str, [Marker => Str, MaxItems => Int, PathPrefix => Str])

Each argument is described in detail in: L<Paws::IAM::ListAttachedGroupPolicies>

Returns: a L<Paws::IAM::ListAttachedGroupPoliciesResponse> instance

  

Lists all managed policies that are attached to the specified group.

A group can also have inline policies embedded with it. To list the
inline policies for a group, use the ListGroupPolicies API. For
information about policies, refer to Managed Policies and Inline
Policies in the I<Using IAM> guide.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters. You can use the C<PathPrefix> parameter to limit the list
of policies to only those matching the specified path prefix. If there
are no policies attached to the specified group (or none that match the
specified path prefix), the action returns an empty list.











=head2 ListAttachedRolePolicies(RoleName => Str, [Marker => Str, MaxItems => Int, PathPrefix => Str])

Each argument is described in detail in: L<Paws::IAM::ListAttachedRolePolicies>

Returns: a L<Paws::IAM::ListAttachedRolePoliciesResponse> instance

  

Lists all managed policies that are attached to the specified role.

A role can also have inline policies embedded with it. To list the
inline policies for a role, use the ListRolePolicies API. For
information about policies, refer to Managed Policies and Inline
Policies in the I<Using IAM> guide.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters. You can use the C<PathPrefix> parameter to limit the list
of policies to only those matching the specified path prefix. If there
are no policies attached to the specified role (or none that match the
specified path prefix), the action returns an empty list.











=head2 ListAttachedUserPolicies(UserName => Str, [Marker => Str, MaxItems => Int, PathPrefix => Str])

Each argument is described in detail in: L<Paws::IAM::ListAttachedUserPolicies>

Returns: a L<Paws::IAM::ListAttachedUserPoliciesResponse> instance

  

Lists all managed policies that are attached to the specified user.

A user can also have inline policies embedded with it. To list the
inline policies for a user, use the ListUserPolicies API. For
information about policies, refer to Managed Policies and Inline
Policies in the I<Using IAM> guide.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters. You can use the C<PathPrefix> parameter to limit the list
of policies to only those matching the specified path prefix. If there
are no policies attached to the specified group (or none that match the
specified path prefix), the action returns an empty list.











=head2 ListEntitiesForPolicy(PolicyArn => Str, [EntityFilter => Str, Marker => Str, MaxItems => Int, PathPrefix => Str])

Each argument is described in detail in: L<Paws::IAM::ListEntitiesForPolicy>

Returns: a L<Paws::IAM::ListEntitiesForPolicyResponse> instance

  

Lists all users, groups, and roles that the specified managed policy is
attached to.

You can use the optional C<EntityFilter> parameter to limit the results
to a particular type of entity (users, groups, or roles). For example,
to list only the roles that are attached to the specified policy, set
C<EntityFilter> to C<Role>.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters.











=head2 ListGroupPolicies(GroupName => Str, [Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::IAM::ListGroupPolicies>

Returns: a L<Paws::IAM::ListGroupPoliciesResponse> instance

  

Lists the names of the inline policies that are embedded in the
specified group.

A group can also have managed policies attached to it. To list the
managed policies that are attached to a group, use
ListAttachedGroupPolicies. For more information about policies, refer
to Managed Policies and Inline Policies in the I<Using IAM> guide.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters. If there are no inline policies embedded with the specified
group, the action returns an empty list.











=head2 ListGroups([Marker => Str, MaxItems => Int, PathPrefix => Str])

Each argument is described in detail in: L<Paws::IAM::ListGroups>

Returns: a L<Paws::IAM::ListGroupsResponse> instance

  

Lists the groups that have the specified path prefix.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters.











=head2 ListGroupsForUser(UserName => Str, [Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::IAM::ListGroupsForUser>

Returns: a L<Paws::IAM::ListGroupsForUserResponse> instance

  

Lists the groups the specified user belongs to.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters.











=head2 ListInstanceProfiles([Marker => Str, MaxItems => Int, PathPrefix => Str])

Each argument is described in detail in: L<Paws::IAM::ListInstanceProfiles>

Returns: a L<Paws::IAM::ListInstanceProfilesResponse> instance

  

Lists the instance profiles that have the specified path prefix. If
there are none, the action returns an empty list. For more information
about instance profiles, go to About Instance Profiles.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters.











=head2 ListInstanceProfilesForRole(RoleName => Str, [Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::IAM::ListInstanceProfilesForRole>

Returns: a L<Paws::IAM::ListInstanceProfilesForRoleResponse> instance

  

Lists the instance profiles that have the specified associated role. If
there are none, the action returns an empty list. For more information
about instance profiles, go to About Instance Profiles.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters.











=head2 ListMFADevices([Marker => Str, MaxItems => Int, UserName => Str])

Each argument is described in detail in: L<Paws::IAM::ListMFADevices>

Returns: a L<Paws::IAM::ListMFADevicesResponse> instance

  

Lists the MFA devices. If the request includes the user name, then this
action lists all the MFA devices associated with the specified user
name. If you do not specify a user name, IAM determines the user name
implicitly based on the AWS access key ID signing the request.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters.











=head2 ListOpenIDConnectProviders( => )

Each argument is described in detail in: L<Paws::IAM::ListOpenIDConnectProviders>

Returns: a L<Paws::IAM::ListOpenIDConnectProvidersResponse> instance

  

Lists information about the OpenID Connect providers in the AWS
account.











=head2 ListPolicies([Marker => Str, MaxItems => Int, OnlyAttached => Bool, PathPrefix => Str, Scope => Str])

Each argument is described in detail in: L<Paws::IAM::ListPolicies>

Returns: a L<Paws::IAM::ListPoliciesResponse> instance

  

Lists all the managed policies that are available to your account,
including your own customer managed policies and all AWS managed
policies.

You can filter the list of policies that is returned using the optional
C<OnlyAttached>, C<Scope>, and C<PathPrefix> parameters. For example,
to list only the customer managed policies in your AWS account, set
C<Scope> to C<Local>. To list only AWS managed policies, set C<Scope>
to C<AWS>.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters.

For more information about managed policies, refer to Managed Policies
and Inline Policies in the I<Using IAM> guide.











=head2 ListPolicyVersions(PolicyArn => Str, [Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::IAM::ListPolicyVersions>

Returns: a L<Paws::IAM::ListPolicyVersionsResponse> instance

  

Lists information about the versions of the specified managed policy,
including the version that is set as the policy's default version.

For more information about managed policies, refer to Managed Policies
and Inline Policies in the I<Using IAM> guide.











=head2 ListRolePolicies(RoleName => Str, [Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::IAM::ListRolePolicies>

Returns: a L<Paws::IAM::ListRolePoliciesResponse> instance

  

Lists the names of the inline policies that are embedded in the
specified role.

A role can also have managed policies attached to it. To list the
managed policies that are attached to a role, use
ListAttachedRolePolicies. For more information about policies, refer to
Managed Policies and Inline Policies in the I<Using IAM> guide.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters. If there are no inline policies embedded with the specified
role, the action returns an empty list.











=head2 ListRoles([Marker => Str, MaxItems => Int, PathPrefix => Str])

Each argument is described in detail in: L<Paws::IAM::ListRoles>

Returns: a L<Paws::IAM::ListRolesResponse> instance

  

Lists the roles that have the specified path prefix. If there are none,
the action returns an empty list. For more information about roles, go
to Working with Roles.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters.











=head2 ListSAMLProviders( => )

Each argument is described in detail in: L<Paws::IAM::ListSAMLProviders>

Returns: a L<Paws::IAM::ListSAMLProvidersResponse> instance

  

Lists the SAML providers in the account.

This operation requires Signature Version 4.











=head2 ListServerCertificates([Marker => Str, MaxItems => Int, PathPrefix => Str])

Each argument is described in detail in: L<Paws::IAM::ListServerCertificates>

Returns: a L<Paws::IAM::ListServerCertificatesResponse> instance

  

Lists the server certificates that have the specified path prefix. If
none exist, the action returns an empty list.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters.











=head2 ListSigningCertificates([Marker => Str, MaxItems => Int, UserName => Str])

Each argument is described in detail in: L<Paws::IAM::ListSigningCertificates>

Returns: a L<Paws::IAM::ListSigningCertificatesResponse> instance

  

Returns information about the signing certificates associated with the
specified user. If there are none, the action returns an empty list.

Although each user is limited to a small number of signing
certificates, you can still paginate the results using the C<MaxItems>
and C<Marker> parameters.

If the C<UserName> field is not specified, the user name is determined
implicitly based on the AWS access key ID used to sign the request.
Because this action works for access keys under the AWS account, you
can use this action to manage root credentials even if the AWS account
has no associated users.











=head2 ListUserPolicies(UserName => Str, [Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::IAM::ListUserPolicies>

Returns: a L<Paws::IAM::ListUserPoliciesResponse> instance

  

Lists the names of the inline policies embedded in the specified user.

A user can also have managed policies attached to it. To list the
managed policies that are attached to a user, use
ListAttachedUserPolicies. For more information about policies, refer to
Managed Policies and Inline Policies in the I<Using IAM> guide.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters. If there are no inline policies embedded with the specified
user, the action returns an empty list.











=head2 ListUsers([Marker => Str, MaxItems => Int, PathPrefix => Str])

Each argument is described in detail in: L<Paws::IAM::ListUsers>

Returns: a L<Paws::IAM::ListUsersResponse> instance

  

Lists the IAM users that have the specified path prefix. If no path
prefix is specified, the action returns all users in the AWS account.
If there are none, the action returns an empty list.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters.











=head2 ListVirtualMFADevices([AssignmentStatus => Str, Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::IAM::ListVirtualMFADevices>

Returns: a L<Paws::IAM::ListVirtualMFADevicesResponse> instance

  

Lists the virtual MFA devices under the AWS account by assignment
status. If you do not specify an assignment status, the action returns
a list of all virtual MFA devices. Assignment status can be
C<Assigned>, C<Unassigned>, or C<Any>.

You can paginate the results using the C<MaxItems> and C<Marker>
parameters.











=head2 PutGroupPolicy(GroupName => Str, PolicyDocument => Str, PolicyName => Str)

Each argument is described in detail in: L<Paws::IAM::PutGroupPolicy>

Returns: nothing

  

Adds (or updates) an inline policy document that is embedded in the
specified group.

A user can also have managed policies attached to it. To attach a
managed policy to a group, use AttachGroupPolicy. To create a new
managed policy, use CreatePolicy. For information about policies, refer
to Managed Policies and Inline Policies in the I<Using IAM> guide.

For information about limits on the number of inline policies that you
can embed in a group, see Limitations on IAM Entities in the I<Using
IAM> guide.

Because policy documents can be large, you should use POST rather than
GET when calling C<PutGroupPolicy>. For general information about using
the Query API with IAM, go to Making Query Requests in the I<Using IAM>
guide.











=head2 PutRolePolicy(PolicyDocument => Str, PolicyName => Str, RoleName => Str)

Each argument is described in detail in: L<Paws::IAM::PutRolePolicy>

Returns: nothing

  

Adds (or updates) an inline policy document that is embedded in the
specified role.

When you embed an inline policy in a role, the inline policy is used as
the role's access (permissions) policy. The role's trust policy is
created at the same time as the role, using CreateRole. You can update
a role's trust policy using UpdateAssumeRolePolicy. For more
information about roles, go to Using Roles to Delegate Permissions and
Federate Identities.

A role can also have a managed policy attached to it. To attach a
managed policy to a role, use AttachRolePolicy. To create a new managed
policy, use CreatePolicy. For information about policies, refer to
Managed Policies and Inline Policies in the I<Using IAM> guide.

For information about limits on the number of inline policies that you
can embed with a role, see Limitations on IAM Entities in the I<Using
IAM> guide.

Because policy documents can be large, you should use POST rather than
GET when calling C<PutRolePolicy>. For general information about using
the Query API with IAM, go to Making Query Requests in the I<Using IAM>
guide.











=head2 PutUserPolicy(PolicyDocument => Str, PolicyName => Str, UserName => Str)

Each argument is described in detail in: L<Paws::IAM::PutUserPolicy>

Returns: nothing

  

Adds (or updates) an inline policy document that is embedded in the
specified user.

A user can also have a managed policy attached to it. To attach a
managed policy to a user, use AttachUserPolicy. To create a new managed
policy, use CreatePolicy. For information about policies, refer to
Managed Policies and Inline Policies in the I<Using IAM> guide.

For information about limits on the number of inline policies that you
can embed in a user, see Limitations on IAM Entities in the I<Using
IAM> guide.

Because policy documents can be large, you should use POST rather than
GET when calling C<PutUserPolicy>. For general information about using
the Query API with IAM, go to Making Query Requests in the I<Using IAM>
guide.











=head2 RemoveClientIDFromOpenIDConnectProvider(ClientID => Str, OpenIDConnectProviderArn => Str)

Each argument is described in detail in: L<Paws::IAM::RemoveClientIDFromOpenIDConnectProvider>

Returns: nothing

  

Removes the specified client ID (also known as audience) from the list
of client IDs registered for the specified IAM OpenID Connect provider.

This action is idempotent; it does not fail or return an error if you
try to remove a client ID that was removed previously.











=head2 RemoveRoleFromInstanceProfile(InstanceProfileName => Str, RoleName => Str)

Each argument is described in detail in: L<Paws::IAM::RemoveRoleFromInstanceProfile>

Returns: nothing

  

Removes the specified role from the specified instance profile.

Make sure you do not have any Amazon EC2 instances running with the
role you are about to remove from the instance profile. Removing a role
from an instance profile that is associated with a running instance
will break any applications running on the instance.

For more information about roles, go to Working with Roles. For more
information about instance profiles, go to About Instance Profiles.











=head2 RemoveUserFromGroup(GroupName => Str, UserName => Str)

Each argument is described in detail in: L<Paws::IAM::RemoveUserFromGroup>

Returns: nothing

  

Removes the specified user from the specified group.











=head2 ResyncMFADevice(AuthenticationCode1 => Str, AuthenticationCode2 => Str, SerialNumber => Str, UserName => Str)

Each argument is described in detail in: L<Paws::IAM::ResyncMFADevice>

Returns: nothing

  

Synchronizes the specified MFA device with AWS servers.

For more information about creating and working with virtual MFA
devices, go to Using a Virtual MFA Device in the I<Using IAM> guide.











=head2 SetDefaultPolicyVersion(PolicyArn => Str, VersionId => Str)

Each argument is described in detail in: L<Paws::IAM::SetDefaultPolicyVersion>

Returns: nothing

  

Sets the specified version of the specified policy as the policy's
default (operative) version.

This action affects all users, groups, and roles that the policy is
attached to. To list the users, groups, and roles that the policy is
attached to, use the ListEntitiesForPolicy API.

For information about managed policies, refer to Managed Policies and
Inline Policies in the I<Using IAM> guide.











=head2 UpdateAccessKey(AccessKeyId => Str, Status => Str, [UserName => Str])

Each argument is described in detail in: L<Paws::IAM::UpdateAccessKey>

Returns: nothing

  

Changes the status of the specified access key from Active to Inactive,
or vice versa. This action can be used to disable a user's key as part
of a key rotation work flow.

If the C<UserName> field is not specified, the UserName is determined
implicitly based on the AWS access key ID used to sign the request.
Because this action works for access keys under the AWS account, you
can use this action to manage root credentials even if the AWS account
has no associated users.

For information about rotating keys, see Managing Keys and Certificates
in the I<Using IAM> guide.











=head2 UpdateAccountPasswordPolicy([AllowUsersToChangePassword => Bool, HardExpiry => Bool, MaxPasswordAge => Int, MinimumPasswordLength => Int, PasswordReusePrevention => Int, RequireLowercaseCharacters => Bool, RequireNumbers => Bool, RequireSymbols => Bool, RequireUppercaseCharacters => Bool])

Each argument is described in detail in: L<Paws::IAM::UpdateAccountPasswordPolicy>

Returns: nothing

  

Updates the password policy settings for the AWS account.

This action does not support partial updates. No parameters are
required, but if you do not specify a parameter, that parameter's value
reverts to its default value. See the B<Request Parameters> section for
each parameter's default value.

For more information about using a password policy, see Managing an IAM
Password Policy in the I<Using IAM> guide.











=head2 UpdateAssumeRolePolicy(PolicyDocument => Str, RoleName => Str)

Each argument is described in detail in: L<Paws::IAM::UpdateAssumeRolePolicy>

Returns: nothing

  

Updates the policy that grants an entity permission to assume a role.
For more information about roles, go to Using Roles to Delegate
Permissions and Federate Identities.











=head2 UpdateGroup(GroupName => Str, [NewGroupName => Str, NewPath => Str])

Each argument is described in detail in: L<Paws::IAM::UpdateGroup>

Returns: nothing

  

Updates the name and/or the path of the specified group.

You should understand the implications of changing a group's path or
name. For more information, see Renaming Users and Groups in the
I<Using IAM> guide. To change a group name the requester must have
appropriate permissions on both the source object and the target
object. For example, to change Managers to MGRs, the entity making the
request must have permission on Managers and MGRs, or must have
permission on all (*). For more information about permissions, see
Permissions and Policies.











=head2 UpdateLoginProfile(UserName => Str, [Password => Str, PasswordResetRequired => Bool])

Each argument is described in detail in: L<Paws::IAM::UpdateLoginProfile>

Returns: nothing

  

Changes the password for the specified user.

Users can change their own passwords by calling ChangePassword. For
more information about modifying passwords, see Managing Passwords in
the I<Using IAM> guide.











=head2 UpdateOpenIDConnectProviderThumbprint(OpenIDConnectProviderArn => Str, ThumbprintList => ArrayRef[Str])

Each argument is described in detail in: L<Paws::IAM::UpdateOpenIDConnectProviderThumbprint>

Returns: nothing

  

Replaces the existing list of server certificate thumbprints with a new
list.

The list that you pass with this action completely replaces the
existing list of thumbprints. (The lists are not merged.)

Typically, you need to update a thumbprint only when the identity
provider's certificate changes, which occurs rarely. However, if the
provider's certificate I<does> change, any attempt to assume an IAM
role that specifies the OIDC provider as a principal will fail until
the certificate thumbprint is updated.

Because trust for the OpenID Connect provider is ultimately derived
from the provider's certificate and is validated by the thumbprint, it
is a best practice to limit access to the
C<UpdateOpenIDConnectProviderThumbprint> action to highly-privileged
users.











=head2 UpdateSAMLProvider(SAMLMetadataDocument => Str, SAMLProviderArn => Str)

Each argument is described in detail in: L<Paws::IAM::UpdateSAMLProvider>

Returns: a L<Paws::IAM::UpdateSAMLProviderResponse> instance

  

Updates the metadata document for an existing SAML provider.

This operation requires Signature Version 4.











=head2 UpdateServerCertificate(ServerCertificateName => Str, [NewPath => Str, NewServerCertificateName => Str])

Each argument is described in detail in: L<Paws::IAM::UpdateServerCertificate>

Returns: nothing

  

Updates the name and/or the path of the specified server certificate.

You should understand the implications of changing a server
certificate's path or name. For more information, see Managing Server
Certificates in the I<Using IAM> guide. To change a server certificate
name the requester must have appropriate permissions on both the source
object and the target object. For example, to change the name from
ProductionCert to ProdCert, the entity making the request must have
permission on ProductionCert and ProdCert, or must have permission on
all (*). For more information about permissions, see Permissions and
Policies.











=head2 UpdateSigningCertificate(CertificateId => Str, Status => Str, [UserName => Str])

Each argument is described in detail in: L<Paws::IAM::UpdateSigningCertificate>

Returns: nothing

  

Changes the status of the specified signing certificate from active to
disabled, or vice versa. This action can be used to disable a user's
signing certificate as part of a certificate rotation work flow.

If the C<UserName> field is not specified, the UserName is determined
implicitly based on the AWS access key ID used to sign the request.
Because this action works for access keys under the AWS account, you
can use this action to manage root credentials even if the AWS account
has no associated users.











=head2 UpdateUser(UserName => Str, [NewPath => Str, NewUserName => Str])

Each argument is described in detail in: L<Paws::IAM::UpdateUser>

Returns: nothing

  

Updates the name and/or the path of the specified user.

You should understand the implications of changing a user's path or
name. For more information, see Renaming Users and Groups in the
I<Using IAM> guide. To change a user name the requester must have
appropriate permissions on both the source object and the target
object. For example, to change Bob to Robert, the entity making the
request must have permission on Bob and Robert, or must have permission
on all (*). For more information about permissions, see Permissions and
Policies.











=head2 UploadServerCertificate(CertificateBody => Str, PrivateKey => Str, ServerCertificateName => Str, [CertificateChain => Str, Path => Str])

Each argument is described in detail in: L<Paws::IAM::UploadServerCertificate>

Returns: a L<Paws::IAM::UploadServerCertificateResponse> instance

  

Uploads a server certificate entity for the AWS account. The server
certificate entity includes a public key certificate, a private key,
and an optional certificate chain, which should all be PEM-encoded.

For information about the number of server certificates you can upload,
see Limitations on IAM Entities in the I<Using IAM> guide.

Because the body of the public key certificate, private key, and the
certificate chain can be large, you should use POST rather than GET
when calling C<UploadServerCertificate>. For information about setting
up signatures and authorization through the API, go to Signing AWS API
Requests in the I<AWS General Reference>. For general information about
using the Query API with IAM, go to Making Query Requests in the
I<Using IAM> guide.











=head2 UploadSigningCertificate(CertificateBody => Str, [UserName => Str])

Each argument is described in detail in: L<Paws::IAM::UploadSigningCertificate>

Returns: a L<Paws::IAM::UploadSigningCertificateResponse> instance

  

Uploads an X.509 signing certificate and associates it with the
specified user. Some AWS services use X.509 signing certificates to
validate requests that are signed with a corresponding private key.
When you upload the certificate, its default status is C<Active>.

If the C<UserName> field is not specified, the user name is determined
implicitly based on the AWS access key ID used to sign the request.
Because this action works for access keys under the AWS account, you
can use this action to manage root credentials even if the AWS account
has no associated users.

Because the body of a X.509 certificate can be large, you should use
POST rather than GET when calling C<UploadSigningCertificate>. For
information about setting up signatures and authorization through the
API, go to Signing AWS API Requests in the I<AWS General Reference>.
For general information about using the Query API with IAM, go to
Making Query Requests in the I<Using IAM>guide.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

