
package Paws::IAM::RemoveClientIDFromOpenIDConnectProvider {
  use Moose;
  has ClientID => (is => 'ro', isa => 'Str', required => 1);
  has OpenIDConnectProviderArn => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RemoveClientIDFromOpenIDConnectProvider');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::RemoveClientIDFromOpenIDConnectProvider - Arguments for method RemoveClientIDFromOpenIDConnectProvider on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method RemoveClientIDFromOpenIDConnectProvider on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method RemoveClientIDFromOpenIDConnectProvider.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RemoveClientIDFromOpenIDConnectProvider.

As an example:

  $service_obj->RemoveClientIDFromOpenIDConnectProvider(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ClientID => Str

  

The client ID (also known as audience) to remove from the IAM OpenID
Connect provider. For more information about client IDs, see
CreateOpenIDConnectProvider.










=head2 B<REQUIRED> OpenIDConnectProviderArn => Str

  

The Amazon Resource Name (ARN) of the IAM OpenID Connect (OIDC)
provider to remove the client ID from. You can get a list of OIDC
provider ARNs by using the ListOpenIDConnectProviders action.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RemoveClientIDFromOpenIDConnectProvider in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

