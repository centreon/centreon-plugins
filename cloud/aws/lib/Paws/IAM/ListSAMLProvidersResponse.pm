
package Paws::IAM::ListSAMLProvidersResponse {
  use Moose;
  has SAMLProviderList => (is => 'ro', isa => 'ArrayRef[Paws::IAM::SAMLProviderListEntry]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::ListSAMLProvidersResponse

=head1 ATTRIBUTES

=head2 SAMLProviderList => ArrayRef[Paws::IAM::SAMLProviderListEntry]

  

The list of SAML providers for this account.











=cut

