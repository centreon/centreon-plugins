
package Paws::CloudSearchDomain::SearchResponse {
  use Moose;
  has facets => (is => 'ro', isa => 'Paws::CloudSearchDomain::Facets');
  has hits => (is => 'ro', isa => 'Paws::CloudSearchDomain::Hits');
  has status => (is => 'ro', isa => 'Paws::CloudSearchDomain::SearchStatus');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearchDomain::SearchResponse

=head1 ATTRIBUTES

=head2 facets => Paws::CloudSearchDomain::Facets

  

The requested facet information.









=head2 hits => Paws::CloudSearchDomain::Hits

  

The documents that match the search criteria.









=head2 status => Paws::CloudSearchDomain::SearchStatus

  

The status information returned for the search request.











=cut

