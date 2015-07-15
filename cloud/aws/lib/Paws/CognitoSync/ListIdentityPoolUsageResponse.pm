
package Paws::CognitoSync::ListIdentityPoolUsageResponse {
  use Moose;
  has Count => (is => 'ro', isa => 'Int');
  has IdentityPoolUsages => (is => 'ro', isa => 'ArrayRef[Paws::CognitoSync::IdentityPoolUsage]');
  has MaxResults => (is => 'ro', isa => 'Int');
  has NextToken => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CognitoSync::ListIdentityPoolUsageResponse

=head1 ATTRIBUTES

=head2 Count => Int

  

Total number of identities for the identity pool.









=head2 IdentityPoolUsages => ArrayRef[Paws::CognitoSync::IdentityPoolUsage]

  

Usage information for the identity pools.









=head2 MaxResults => Int

  

The maximum number of results to be returned.









=head2 NextToken => Str

  

A pagination token for obtaining the next page of results.











=cut

