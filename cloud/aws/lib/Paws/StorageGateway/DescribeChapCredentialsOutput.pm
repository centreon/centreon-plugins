
package Paws::StorageGateway::DescribeChapCredentialsOutput {
  use Moose;
  has ChapCredentials => (is => 'ro', isa => 'ArrayRef[Paws::StorageGateway::ChapInfo]');

}

### main pod documentation begin ###

=head1 NAME

Paws::StorageGateway::DescribeChapCredentialsOutput

=head1 ATTRIBUTES

=head2 ChapCredentials => ArrayRef[Paws::StorageGateway::ChapInfo]

  

An array of ChapInfo objects that represent CHAP credentials. Each
object in the array contains CHAP credential information for one
target-initiator pair. If no CHAP credentials are set, an empty array
is returned. CHAP credential information is provided in a JSON object
with the following fields:

=over

=item *

B<InitiatorName>: The iSCSI initiator that connects to the target.

=item *

B<SecretToAuthenticateInitiator>: The secret key that the initiator
(for example, the Windows client) must provide to participate in mutual
CHAP with the target.

=item *

B<SecretToAuthenticateTarget>: The secret key that the target must
provide to participate in mutual CHAP with the initiator (e.g. Windows
client).

=item *

B<TargetARN>: The Amazon Resource Name (ARN) of the storage volume.

=back











=cut

1;