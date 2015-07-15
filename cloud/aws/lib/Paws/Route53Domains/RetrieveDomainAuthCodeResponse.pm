
package Paws::Route53Domains::RetrieveDomainAuthCodeResponse {
  use Moose;
  has AuthCode => (is => 'ro', isa => 'Str', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::Route53Domains::RetrieveDomainAuthCodeResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> AuthCode => Str

  

The authorization code for the domain.

Type: String











=cut

1;