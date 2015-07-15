
package Paws::IAM::CreateOpenIDConnectProvider {
  use Moose;
  has ClientIDList => (is => 'ro', isa => 'ArrayRef[Str]');
  has ThumbprintList => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has Url => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateOpenIDConnectProvider');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::IAM::CreateOpenIDConnectProviderResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateOpenIDConnectProviderResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::CreateOpenIDConnectProvider - Arguments for method CreateOpenIDConnectProvider on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateOpenIDConnectProvider on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method CreateOpenIDConnectProvider.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateOpenIDConnectProvider.

As an example:

  $service_obj->CreateOpenIDConnectProvider(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ClientIDList => ArrayRef[Str]

  

A list of client IDs (also known as audiences). When a mobile or web
app registers with an OpenID Connect provider, they establish a value
that identifies the application. (This is the value that's sent as the
C<client_id> parameter on OAuth requests.)

You can register multiple client IDs with the same provider. For
example, you might have multiple applications that use the same OIDC
provider. You cannot register more than 100 client IDs with a single
IAM OIDC provider.

There is no defined format for a client ID. The
C<CreateOpenIDConnectProviderRequest> action accepts client IDs up to
255 characters long.










=head2 B<REQUIRED> ThumbprintList => ArrayRef[Str]

  

A list of server certificate thumbprints for the OpenID Connect (OIDC)
identity provider's server certificate(s). Typically this list includes
only one entry. However, IAM lets you have up to five thumbprints for
an OIDC provider. This lets you maintain multiple thumbprints if the
identity provider is rotating certificates.

The server certificate thumbprint is the hex-encoded SHA-1 hash value
of the X.509 certificate used by the domain where the OpenID Connect
provider makes its keys available. It is always a 40-character string.

You must provide at least one thumbprint when creating an IAM OIDC
provider. For example, if the OIDC provider is C<server.example.com>
and the provider stores its keys at
"https://keys.server.example.com/openid-connect", the thumbprint string
would be the hex-encoded SHA-1 hash value of the certificate used by
https://keys.server.example.com.

For more information about obtaining the OIDC provider's thumbprint,
see Obtaining the Thumbprint for an OpenID Connect Provider in the
I<Using IAM> guide.










=head2 B<REQUIRED> Url => Str

  

The URL of the identity provider. The URL must begin with "https://"
and should correspond to the C<iss> claim in the provider's OpenID
Connect ID tokens. Per the OIDC standard, path components are allowed
but query parameters are not. Typically the URL consists of only a host
name, like "https://server.example.org" or "https://example.com".

You cannot register the same provider multiple times in a single AWS
account. If you try to submit a URL that has already been used for an
OpenID Connect provider in the AWS account, you will get an error.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateOpenIDConnectProvider in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

