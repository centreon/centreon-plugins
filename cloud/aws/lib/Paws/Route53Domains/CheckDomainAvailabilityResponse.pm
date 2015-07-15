
package Paws::Route53Domains::CheckDomainAvailabilityResponse {
  use Moose;
  has Availability => (is => 'ro', isa => 'Str', required => 1);

}

### main pod documentation begin ###

=head1 NAME

Paws::Route53Domains::CheckDomainAvailabilityResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> Availability => Str

  

Whether the domain name is available for registering.

You can only register domains designated as C<AVAILABLE>.

Type: String

Valid values:

=over

=item * C<AVAILABLE> E<acirc>E<128>E<147> The domain name is available.

=item * C<AVAILABLE_RESERVED> E<acirc>E<128>E<147> The domain name is
reserved under specific conditions.

=item * C<AVAILABLE_PREORDER> E<acirc>E<128>E<147> The domain name is
available and can be preordered.

=item * C<UNAVAILABLE> E<acirc>E<128>E<147> The domain name is not
available.

=item * C<UNAVAILABLE_PREMIUM> E<acirc>E<128>E<147> The domain name is
not available.

=item * C<UNAVAILABLE_RESTRICTED> E<acirc>E<128>E<147> The domain name
is forbidden.

=item * C<RESERVED> E<acirc>E<128>E<147> The domain name has been
reserved for another person or organization.

=item * C<DONT_KNOW> E<acirc>E<128>E<147> The TLD registry didn't reply
with a definitive answer about whether the domain name is available.
Amazon Route 53 can return this response for a variety of reasons, for
example, the registry is performing maintenance. Try again later.

=back











=cut

1;