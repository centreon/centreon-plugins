
package Paws::CognitoIdentity::IdentityPool {
  use Moose;
  has AllowUnauthenticatedIdentities => (is => 'ro', isa => 'Bool', required => 1);
  has DeveloperProviderName => (is => 'ro', isa => 'Str');
  has IdentityPoolId => (is => 'ro', isa => 'Str', required => 1);
  has IdentityPoolName => (is => 'ro', isa => 'Str', required => 1);
  has OpenIdConnectProviderARNs => (is => 'ro', isa => 'ArrayRef[Str]');
  has SupportedLoginProviders => (is => 'ro', isa => 'Paws::CognitoIdentity::IdentityProviders');

}

### main pod documentation begin ###

=head1 NAME

Paws::CognitoIdentity::IdentityPool

=head1 ATTRIBUTES

=head2 B<REQUIRED> AllowUnauthenticatedIdentities => Bool

  

TRUE if the identity pool supports unauthenticated logins.









=head2 DeveloperProviderName => Str

  

The "domain" by which Cognito will refer to your users.









=head2 B<REQUIRED> IdentityPoolId => Str

  

An identity pool ID in the format REGION:GUID.









=head2 B<REQUIRED> IdentityPoolName => Str

  

A string that you provide.









=head2 OpenIdConnectProviderARNs => ArrayRef[Str]

  

A list of OpendID Connect provider ARNs.









=head2 SupportedLoginProviders => Paws::CognitoIdentity::IdentityProviders

  

Optional key:value pairs mapping provider names to provider app IDs.











=cut

1;