
package Paws::IAM::GetOpenIDConnectProviderResponse {
  use Moose;
  has ClientIDList => (is => 'ro', isa => 'ArrayRef[Str]');
  has CreateDate => (is => 'ro', isa => 'Str');
  has ThumbprintList => (is => 'ro', isa => 'ArrayRef[Str]');
  has Url => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::GetOpenIDConnectProviderResponse

=head1 ATTRIBUTES

=head2 ClientIDList => ArrayRef[Str]

  

A list of client IDs (also known as audiences) that are associated with
the specified IAM OpenID Connect provider. For more information, see
CreateOpenIDConnectProvider.









=head2 CreateDate => Str

  

The date and time when the IAM OpenID Connect provider entity was
created in the AWS account.









=head2 ThumbprintList => ArrayRef[Str]

  

A list of certificate thumbprints that are associated with the
specified IAM OpenID Connect provider. For more information, see
CreateOpenIDConnectProvider.









=head2 Url => Str

  

The URL that the IAM OpenID Connect provider is associated with. For
more information, see CreateOpenIDConnectProvider.











=cut

