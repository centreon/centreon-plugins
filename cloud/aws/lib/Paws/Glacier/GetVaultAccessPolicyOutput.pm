
package Paws::Glacier::GetVaultAccessPolicyOutput {
  use Moose;
  has policy => (is => 'ro', isa => 'Paws::Glacier::VaultAccessPolicy');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Glacier::GetVaultAccessPolicyOutput

=head1 ATTRIBUTES

=head2 policy => Paws::Glacier::VaultAccessPolicy

  

Contains the returned vault access policy as a JSON string.











=cut

