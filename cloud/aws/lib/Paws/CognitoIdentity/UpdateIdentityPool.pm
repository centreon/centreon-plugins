
package Paws::CognitoIdentity::UpdateIdentityPool {
  use Moose;
  has AllowUnauthenticatedIdentities => (is => 'ro', isa => 'Bool', required => 1);
  has DeveloperProviderName => (is => 'ro', isa => 'Str');
  has IdentityPoolId => (is => 'ro', isa => 'Str', required => 1);
  has IdentityPoolName => (is => 'ro', isa => 'Str', required => 1);
  has OpenIdConnectProviderARNs => (is => 'ro', isa => 'ArrayRef[Str]');
  has SupportedLoginProviders => (is => 'ro', isa => 'Paws::CognitoIdentity::IdentityProviders');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateIdentityPool');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CognitoIdentity::IdentityPool');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoIdentity::UpdateIdentityPool - Arguments for method UpdateIdentityPool on Paws::CognitoIdentity

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateIdentityPool on the 
Amazon Cognito Identity service. Use the attributes of this class
as arguments to method UpdateIdentityPool.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateIdentityPool.

As an example:

  $service_obj->UpdateIdentityPool(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

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












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateIdentityPool in L<Paws::CognitoIdentity>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

