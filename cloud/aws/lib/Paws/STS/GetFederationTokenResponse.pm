
package Paws::STS::GetFederationTokenResponse {
  use Moose;
  has Credentials => (is => 'ro', isa => 'Paws::STS::Credentials');
  has FederatedUser => (is => 'ro', isa => 'Paws::STS::FederatedUser');
  has PackedPolicySize => (is => 'ro', isa => 'Int');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::STS::GetFederationTokenResponse

=head1 ATTRIBUTES

=head2 Credentials => Paws::STS::Credentials

  

Credentials for the service API authentication.









=head2 FederatedUser => Paws::STS::FederatedUser

  

Identifiers for the federated user associated with the credentials
(such as C<arn:aws:sts::123456789012:federated-user/Bob> or
C<123456789012:Bob>). You can use the federated user's ARN in your
resource-based policies, such as an Amazon S3 bucket policy.









=head2 PackedPolicySize => Int

  

A percentage value indicating the size of the policy in packed form.
The service rejects policies for which the packed size is greater than
100 percent of the allowed value.











=cut

