
package Paws::CloudSearch::ListDomainNamesResponse {
  use Moose;
  has DomainNames => (is => 'ro', isa => 'Paws::CloudSearch::DomainNameMap');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::ListDomainNamesResponse

=head1 ATTRIBUTES

=head2 DomainNames => Paws::CloudSearch::DomainNameMap

  

The names of the search domains owned by an account.











=cut

