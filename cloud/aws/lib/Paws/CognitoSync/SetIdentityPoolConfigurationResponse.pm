
package Paws::CognitoSync::SetIdentityPoolConfigurationResponse {
  use Moose;
  has CognitoStreams => (is => 'ro', isa => 'Paws::CognitoSync::CognitoStreams');
  has IdentityPoolId => (is => 'ro', isa => 'Str');
  has PushSync => (is => 'ro', isa => 'Paws::CognitoSync::PushSync');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoSync::SetIdentityPoolConfigurationResponse

=head1 ATTRIBUTES

=head2 CognitoStreams => Paws::CognitoSync::CognitoStreams

  

Options to apply to this identity pool for Amazon Cognito streams.









=head2 IdentityPoolId => Str

  

A name-spaced GUID (for example,
us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon
Cognito.









=head2 PushSync => Paws::CognitoSync::PushSync

  

Options to apply to this identity pool for push synchronization.











=cut

