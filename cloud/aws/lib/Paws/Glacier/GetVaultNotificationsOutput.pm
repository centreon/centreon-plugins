
package Paws::Glacier::GetVaultNotificationsOutput {
  use Moose;
  has vaultNotificationConfig => (is => 'ro', isa => 'Paws::Glacier::VaultNotificationConfig');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Glacier::GetVaultNotificationsOutput

=head1 ATTRIBUTES

=head2 vaultNotificationConfig => Paws::Glacier::VaultNotificationConfig

  

Returns the notification configuration set on the vault.











=cut

