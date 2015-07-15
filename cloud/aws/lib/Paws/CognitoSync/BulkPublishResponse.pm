
package Paws::CognitoSync::BulkPublishResponse {
  use Moose;
  has IdentityPoolId => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoSync::BulkPublishResponse

=head1 ATTRIBUTES

=head2 IdentityPoolId => Str

  

A name-spaced GUID (for example,
us-east-1:23EC4050-6AEA-7089-A2DD-08002EXAMPLE) created by Amazon
Cognito. GUID generation is unique within a region.











=cut

