
package Paws::SES::VerifyDomainIdentityResponse {
  use Moose;
  has VerificationToken => (is => 'ro', isa => 'Str', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::VerifyDomainIdentityResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> VerificationToken => Str

  

A TXT record that must be placed in the DNS settings for the domain, in
order to complete domain verification.











=cut

