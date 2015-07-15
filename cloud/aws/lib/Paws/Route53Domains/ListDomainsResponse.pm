
package Paws::Route53Domains::ListDomainsResponse {
  use Moose;
  has Domains => (is => 'ro', isa => 'ArrayRef[Paws::Route53Domains::DomainSummary]', required => 1);
  has NextPageMarker => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::Route53Domains::ListDomainsResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> Domains => ArrayRef[Paws::Route53Domains::DomainSummary]

  

A summary of domains.

Type: Complex type containing a list of domain summaries.

Children: C<AutoRenew>, C<DomainName>, C<Expiry>, C<TransferLock>









=head2 NextPageMarker => Str

  

If there are more domains than you specified for C<MaxItems> in the
request, submit another request and include the value of
C<NextPageMarker> in the value of C<Marker>.

Type: String

Parent: C<Operations>











=cut

1;