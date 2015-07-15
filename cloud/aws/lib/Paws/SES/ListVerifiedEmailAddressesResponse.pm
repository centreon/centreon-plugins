
package Paws::SES::ListVerifiedEmailAddressesResponse {
  use Moose;
  has VerifiedEmailAddresses => (is => 'ro', isa => 'ArrayRef[Str]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::ListVerifiedEmailAddressesResponse

=head1 ATTRIBUTES

=head2 VerifiedEmailAddresses => ArrayRef[Str]

  

A list of email addresses that have been verified.











=cut

