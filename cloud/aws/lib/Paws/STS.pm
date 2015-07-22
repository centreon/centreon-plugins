package Paws::STS {
  use Moose;
  sub service { 'sts' }
  sub version { '2011-06-15' }
  sub flattened_arrays { 0 }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::QueryCaller', 'Paws::Net::XMLResponse';

  has '+region_rules' => (default => sub {
    my $regioninfo;
      $regioninfo = [
    {
      constraints => [
        [
          'region',
          'startsWith',
          'cn-'
        ]
      ],
      uri => '{scheme}://{service}.cn-north-1.amazonaws.com.cn'
    },
    {
      constraints => [
        [
          'region',
          'startsWith',
          'us-gov'
        ]
      ],
      uri => 'https://{service}.{region}.amazonaws.com'
    },
    {
      constraints => [
        [
          'region',
          'equals',
          undef
        ]
      ],
      properties => {
        credentialScope => {
          region => 'us-east-1'
        }
      },
      uri => 'https://sts.amazonaws.com'
    },
    {
      uri => 'https://{service}.{region}.amazonaws.com'
    }
  ];

    return $regioninfo;
  });

  
  sub AssumeRole {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::STS::AssumeRole', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AssumeRoleWithSAML {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::STS::AssumeRoleWithSAML', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AssumeRoleWithWebIdentity {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::STS::AssumeRoleWithWebIdentity', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DecodeAuthorizationMessage {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::STS::DecodeAuthorizationMessage', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetFederationToken {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::STS::GetFederationToken', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetSessionToken {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::STS::GetSessionToken', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::STS - Perl Interface to AWS AWS Security Token Service

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('STS')->new;
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



AWS Security Token Service

The AWS Security Token Service (STS) is a web service that enables you
to request temporary, limited-privilege credentials for AWS Identity
and Access Management (IAM) users or for users that you authenticate
(federated users). This guide provides descriptions of the STS API. For
more detailed information about using this service, go to Using
Temporary Security Credentials.

As an alternative to using the API, you can use one of the AWS SDKs,
which consist of libraries and sample code for various programming
languages and platforms (Java, Ruby, .NET, iOS, Android, etc.). The
SDKs provide a convenient way to create programmatic access to STS. For
example, the SDKs take care of cryptographically signing requests,
managing errors, and retrying requests automatically. For information
about the AWS SDKs, including how to download and install them, see the
Tools for Amazon Web Services page.

For information about setting up signatures and authorization through
the API, go to Signing AWS API Requests in the I<AWS General
Reference>. For general information about the Query API, go to Making
Query Requests in I<Using IAM>. For information about using security
tokens with other AWS products, go to Using Temporary Security
Credentials to Access AWS in I<Using Temporary Security Credentials>.

If you're new to AWS and need additional technical information about a
specific AWS product, you can find the product's technical
documentation at http://aws.amazon.com/documentation/.

B<Endpoints>

The AWS Security Token Service (STS) has a default endpoint of
https://sts.amazonaws.com that maps to the US East (N. Virginia)
region. Additional regions are available, but must first be activated
in the AWS Management Console before you can use a different region's
endpoint. For more information about activating a region for STS see
Activating STS in a New Region in the I<Using Temporary Security
Credentials> guide.

For information about STS endpoints, see Regions and Endpoints in the
I<AWS General Reference>.

B<Recording API requests>

STS supports AWS CloudTrail, which is a service that records AWS calls
for your AWS account and delivers log files to an Amazon S3 bucket. By
using information collected by CloudTrail, you can determine what
requests were successfully made to STS, who made the request, when it
was made, and so on. To learn more about CloudTrail, including how to
turn it on and find your log files, see the AWS CloudTrail User Guide.










=head1 METHODS

=head2 AssumeRole(RoleArn => Str, RoleSessionName => Str, [DurationSeconds => Int, ExternalId => Str, Policy => Str, SerialNumber => Str, TokenCode => Str])

Each argument is described in detail in: L<Paws::STS::AssumeRole>

Returns: a L<Paws::STS::AssumeRoleResponse> instance

  

Returns a set of temporary security credentials (consisting of an
access key ID, a secret access key, and a security token) that you can
use to access AWS resources that you might not normally have access to.
Typically, you use C<AssumeRole> for cross-account access or
federation.

B<Important:> You cannot call C<AssumeRole> by using AWS account
credentials; access will be denied. You must use IAM user credentials
or temporary security credentials to call C<AssumeRole>.

For cross-account access, imagine that you own multiple accounts and
need to access resources in each account. You could create long-term
credentials in each account to access those resources. However,
managing all those credentials and remembering which one can access
which account can be time consuming. Instead, you can create one set of
long-term credentials in one account and then use temporary security
credentials to access all the other accounts by assuming roles in those
accounts. For more information about roles, see IAM Roles (Delegation
and Federation) in I<Using IAM>.

For federation, you can, for example, grant single sign-on access to
the AWS Management Console. If you already have an identity and
authentication system in your corporate network, you don't have to
recreate user identities in AWS in order to grant those user identities
access to AWS. Instead, after a user has been authenticated, you call
C<AssumeRole> (and specify the role with the appropriate permissions)
to get temporary security credentials for that user. With those
temporary security credentials, you construct a sign-in URL that users
can use to access the console. For more information, see Scenarios for
Granting Temporary Access in I<Using Temporary Security Credentials>.

The temporary security credentials are valid for the duration that you
specified when calling C<AssumeRole>, which can be from 900 seconds (15
minutes) to 3600 seconds (1 hour). The default is 1 hour.

Optionally, you can pass an IAM access policy to this operation. If you
choose not to pass a policy, the temporary security credentials that
are returned by the operation have the permissions that are defined in
the access policy of the role that is being assumed. If you pass a
policy to this operation, the temporary security credentials that are
returned by the operation have the permissions that are allowed by both
the access policy of the role that is being assumed, I<B<and>> the
policy that you pass. This gives you a way to further restrict the
permissions for the resulting temporary security credentials. You
cannot use the passed policy to grant permissions that are in excess of
those allowed by the access policy of the role that is being assumed.
For more information, see Permissions for AssumeRole,
AssumeRoleWithSAML, and AssumeRoleWithWebIdentity in I<Using Temporary
Security Credentials>.

To assume a role, your AWS account must be trusted by the role. The
trust relationship is defined in the role's trust policy when the role
is created. You must also have a policy that allows you to call
C<sts:AssumeRole>.

B<Using MFA with AssumeRole>

You can optionally include multi-factor authentication (MFA)
information when you call C<AssumeRole>. This is useful for
cross-account scenarios in which you want to make sure that the user
who is assuming the role has been authenticated using an AWS MFA
device. In that scenario, the trust policy of the role being assumed
includes a condition that tests for MFA authentication; if the caller
does not include valid MFA information, the request to assume the role
is denied. The condition in a trust policy that tests for MFA
authentication might look like the following example.

C<"Condition": {"Bool": {"aws:MultiFactorAuthPresent": true}}>

For more information, see Configuring MFA-Protected API Access in
I<Using IAM> guide.

To use MFA with C<AssumeRole>, you pass values for the C<SerialNumber>
and C<TokenCode> parameters. The C<SerialNumber> value identifies the
user's hardware or virtual MFA device. The C<TokenCode> is the
time-based one-time password (TOTP) that the MFA devices produces.











=head2 AssumeRoleWithSAML(PrincipalArn => Str, RoleArn => Str, SAMLAssertion => Str, [DurationSeconds => Int, Policy => Str])

Each argument is described in detail in: L<Paws::STS::AssumeRoleWithSAML>

Returns: a L<Paws::STS::AssumeRoleWithSAMLResponse> instance

  

Returns a set of temporary security credentials for users who have been
authenticated via a SAML authentication response. This operation
provides a mechanism for tying an enterprise identity store or
directory to role-based AWS access without user-specific credentials or
configuration.

The temporary security credentials returned by this operation consist
of an access key ID, a secret access key, and a security token.
Applications can use these temporary security credentials to sign calls
to AWS services. The credentials are valid for the duration that you
specified when calling C<AssumeRoleWithSAML>, which can be up to 3600
seconds (1 hour) or until the time specified in the SAML authentication
response's C<SessionNotOnOrAfter> value, whichever is shorter.

The maximum duration for a session is 1 hour, and the minimum duration
is 15 minutes, even if values outside this range are specified.

Optionally, you can pass an IAM access policy to this operation. If you
choose not to pass a policy, the temporary security credentials that
are returned by the operation have the permissions that are defined in
the access policy of the role that is being assumed. If you pass a
policy to this operation, the temporary security credentials that are
returned by the operation have the permissions that are allowed by both
the access policy of the role that is being assumed, I<B<and>> the
policy that you pass. This gives you a way to further restrict the
permissions for the resulting temporary security credentials. You
cannot use the passed policy to grant permissions that are in excess of
those allowed by the access policy of the role that is being assumed.
For more information, see Permissions for AssumeRoleWithSAML in I<Using
Temporary Security Credentials>.

Before your application can call C<AssumeRoleWithSAML>, you must
configure your SAML identity provider (IdP) to issue the claims
required by AWS. Additionally, you must use AWS Identity and Access
Management (IAM) to create a SAML provider entity in your AWS account
that represents your identity provider, and create an IAM role that
specifies this SAML provider in its trust policy.

Calling C<AssumeRoleWithSAML> does not require the use of AWS security
credentials. The identity of the caller is validated by using keys in
the metadata document that is uploaded for the SAML provider entity for
your identity provider.

For more information, see the following resources:

=over

=item * Creating Temporary Security Credentials for SAML Federation.

=item * SAML Providers in I<Using IAM>.

=item * Configuring a Relying Party and Claims in I<Using IAM>.

=item * Creating a Role for SAML-Based Federation in I<Using IAM>.

=back











=head2 AssumeRoleWithWebIdentity(RoleArn => Str, RoleSessionName => Str, WebIdentityToken => Str, [DurationSeconds => Int, Policy => Str, ProviderId => Str])

Each argument is described in detail in: L<Paws::STS::AssumeRoleWithWebIdentity>

Returns: a L<Paws::STS::AssumeRoleWithWebIdentityResponse> instance

  

Returns a set of temporary security credentials for users who have been
authenticated in a mobile or web application with a web identity
provider, such as Amazon Cognito, Login with Amazon, Facebook, Google,
or any OpenID Connect-compatible identity provider.

For mobile applications, we recommend that you use Amazon Cognito. You
can use Amazon Cognito with the AWS SDK for iOS and the AWS SDK for
Android to uniquely identify a user and supply the user with a
consistent identity throughout the lifetime of an application.

To learn more about Amazon Cognito, see Amazon Cognito Overview in the
I<AWS SDK for Android Developer Guide> guide and Amazon Cognito
Overview in the I<AWS SDK for iOS Developer Guide>.

Calling C<AssumeRoleWithWebIdentity> does not require the use of AWS
security credentials. Therefore, you can distribute an application (for
example, on mobile devices) that requests temporary security
credentials without including long-term AWS credentials in the
application, and without deploying server-based proxy services that use
long-term AWS credentials. Instead, the identity of the caller is
validated by using a token from the web identity provider.

The temporary security credentials returned by this API consist of an
access key ID, a secret access key, and a security token. Applications
can use these temporary security credentials to sign calls to AWS
service APIs. The credentials are valid for the duration that you
specified when calling C<AssumeRoleWithWebIdentity>, which can be from
900 seconds (15 minutes) to 3600 seconds (1 hour). By default, the
temporary security credentials are valid for 1 hour.

Optionally, you can pass an IAM access policy to this operation. If you
choose not to pass a policy, the temporary security credentials that
are returned by the operation have the permissions that are defined in
the access policy of the role that is being assumed. If you pass a
policy to this operation, the temporary security credentials that are
returned by the operation have the permissions that are allowed by both
the access policy of the role that is being assumed, I<B<and>> the
policy that you pass. This gives you a way to further restrict the
permissions for the resulting temporary security credentials. You
cannot use the passed policy to grant permissions that are in excess of
those allowed by the access policy of the role that is being assumed.
For more information, see Permissions for AssumeRoleWithWebIdentity.

Before your application can call C<AssumeRoleWithWebIdentity>, you must
have an identity token from a supported identity provider and create a
role that the application can assume. The role that your application
assumes must trust the identity provider that is associated with the
identity token. In other words, the identity provider must be specified
in the role's trust policy.

For more information about how to use web identity federation and the
C<AssumeRoleWithWebIdentity> API, see the following resources:

=over

=item * Creating a Mobile Application with Third-Party Sign-In and
Creating Temporary Security Credentials for Mobile Apps Using
Third-Party Identity Providers.

=item * Web Identity Federation Playground. This interactive website
lets you walk through the process of authenticating via Login with
Amazon, Facebook, or Google, getting temporary security credentials,
and then using those credentials to make a request to AWS.

=item * AWS SDK for iOS and AWS SDK for Android. These toolkits contain
sample apps that show how to invoke the identity providers, and then
how to use the information from these providers to get and use
temporary security credentials.

=item * Web Identity Federation with Mobile Applications. This article
discusses web identity federation and shows an example of how to use
web identity federation to get access to content in Amazon S3.

=back











=head2 DecodeAuthorizationMessage(EncodedMessage => Str)

Each argument is described in detail in: L<Paws::STS::DecodeAuthorizationMessage>

Returns: a L<Paws::STS::DecodeAuthorizationMessageResponse> instance

  

Decodes additional information about the authorization status of a
request from an encoded message returned in response to an AWS request.

For example, if a user is not authorized to perform an action that he
or she has requested, the request returns a
C<Client.UnauthorizedOperation> response (an HTTP 403 response). Some
AWS actions additionally return an encoded message that can provide
details about this authorization failure.

Only certain AWS actions return an encoded authorization message. The
documentation for an individual action indicates whether that action
returns an encoded message in addition to returning an HTTP code.

The message is encoded because the details of the authorization status
can constitute privileged information that the user who requested the
action should not see. To decode an authorization status message, a
user must be granted permissions via an IAM policy to request the
C<DecodeAuthorizationMessage> (C<sts:DecodeAuthorizationMessage>)
action.

The decoded message includes the following type of information:

=over

=item * Whether the request was denied due to an explicit deny or due
to the absence of an explicit allow. For more information, see
Determining Whether a Request is Allowed or Denied in I<Using IAM>.

=item * The principal who made the request.

=item * The requested action.

=item * The requested resource.

=item * The values of condition keys in the context of the user's
request.

=back











=head2 GetFederationToken(Name => Str, [DurationSeconds => Int, Policy => Str])

Each argument is described in detail in: L<Paws::STS::GetFederationToken>

Returns: a L<Paws::STS::GetFederationTokenResponse> instance

  

Returns a set of temporary security credentials (consisting of an
access key ID, a secret access key, and a security token) for a
federated user. A typical use is in a proxy application that gets
temporary security credentials on behalf of distributed applications
inside a corporate network. Because you must call the
C<GetFederationToken> action using the long-term security credentials
of an IAM user, this call is appropriate in contexts where those
credentials can be safely stored, usually in a server-based
application.

If you are creating a mobile-based or browser-based app that can
authenticate users using a web identity provider like Login with
Amazon, Facebook, Google, or an OpenID Connect-compatible identity
provider, we recommend that you use Amazon Cognito or
C<AssumeRoleWithWebIdentity>. For more information, see Creating
Temporary Security Credentials for Mobile Apps Using Identity
Providers.

The C<GetFederationToken> action must be called by using the long-term
AWS security credentials of an IAM user. You can also call
C<GetFederationToken> using the security credentials of an AWS account
(root), but this is not recommended. Instead, we recommend that you
create an IAM user for the purpose of the proxy application and then
attach a policy to the IAM user that limits federated users to only the
actions and resources they need access to. For more information, see
IAM Best Practices in I<Using IAM>.

The temporary security credentials that are obtained by using the
long-term credentials of an IAM user are valid for the specified
duration, between 900 seconds (15 minutes) and 129600 seconds (36
hours). Temporary credentials that are obtained by using AWS account
(root) credentials have a maximum duration of 3600 seconds (1 hour)

B<Permissions>

The permissions for the temporary security credentials returned by
C<GetFederationToken> are determined by a combination of the following:

=over

=item * The policy or policies that are attached to the IAM user whose
credentials are used to call C<GetFederationToken>.

=item * The policy that is passed as a parameter in the call.

=back

The passed policy is attached to the temporary security credentials
that result from the C<GetFederationToken> API call--that is, to the
I<federated user>. When the federated user makes an AWS request, AWS
evaluates the policy attached to the federated user in combination with
the policy or policies attached to the IAM user whose credentials were
used to call C<GetFederationToken>. AWS allows the federated user's
request only when both the federated user I<B<and>> the IAM user are
explicitly allowed to perform the requested action. The passed policy
cannot grant more permissions than those that are defined in the IAM
user policy.

A typical use case is that the permissions of the IAM user whose
credentials are used to call C<GetFederationToken> are designed to
allow access to all the actions and resources that any federated user
will need. Then, for individual users, you pass a policy to the
operation that scopes down the permissions to a level that's
appropriate to that individual user, using a policy that allows only a
subset of permissions that are granted to the IAM user.

If you do not pass a policy, the resulting temporary security
credentials have no effective permissions. The only exception is when
the temporary security credentials are used to access a resource that
has a resource-based policy that specifically allows the federated user
to access the resource.

For more information about how permissions work, see Permissions for
GetFederationToken. For information about using C<GetFederationToken>
to create temporary security credentials, see Creating Temporary
Credentials to Enable Access for Federated Users.











=head2 GetSessionToken([DurationSeconds => Int, SerialNumber => Str, TokenCode => Str])

Each argument is described in detail in: L<Paws::STS::GetSessionToken>

Returns: a L<Paws::STS::GetSessionTokenResponse> instance

  

Returns a set of temporary credentials for an AWS account or IAM user.
The credentials consist of an access key ID, a secret access key, and a
security token. Typically, you use C<GetSessionToken> if you want to
use MFA to protect programmatic calls to specific AWS APIs like Amazon
EC2 C<StopInstances>. MFA-enabled IAM users would need to call
C<GetSessionToken> and submit an MFA code that is associated with their
MFA device. Using the temporary security credentials that are returned
from the call, IAM users can then make programmatic calls to APIs that
require MFA authentication.

The C<GetSessionToken> action must be called by using the long-term AWS
security credentials of the AWS account or an IAM user. Credentials
that are created by IAM users are valid for the duration that you
specify, between 900 seconds (15 minutes) and 129600 seconds (36
hours); credentials that are created by using account credentials have
a maximum duration of 3600 seconds (1 hour).

We recommend that you do not call C<GetSessionToken> with root account
credentials. Instead, follow our best practices by creating one or more
IAM users, giving them the necessary permissions, and using IAM users
for everyday interaction with AWS.

The permissions associated with the temporary security credentials
returned by C<GetSessionToken> are based on the permissions associated
with account or IAM user whose credentials are used to call the action.
If C<GetSessionToken> is called using root account credentials, the
temporary credentials have root account permissions. Similarly, if
C<GetSessionToken> is called using the credentials of an IAM user, the
temporary credentials have the same permissions as the IAM user.

For more information about using C<GetSessionToken> to create temporary
credentials, go to Creating Temporary Credentials to Enable Access for
IAM Users.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

