
package Paws::SES::GetIdentityDkimAttributesResponse {
  use Moose;
  has DkimAttributes => (is => 'ro', isa => 'Paws::SES::DkimAttributes', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::GetIdentityDkimAttributesResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> DkimAttributes => Paws::SES::DkimAttributes

  

The DKIM attributes for an email address or a domain.











=cut

