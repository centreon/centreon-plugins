
package Paws::SDB::ListDomainsResult {
  use Moose;
  has DomainNames => (is => 'ro', isa => 'ArrayRef[Str]', xmlname => 'DomainName', traits => ['Unwrapped',]);
  has NextToken => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SDB::ListDomainsResult

=head1 ATTRIBUTES

=head2 DomainNames => ArrayRef[Str]

  

A list of domain names that match the expression.









=head2 NextToken => Str

  

An opaque token indicating that there are more domains than the
specified C<MaxNumberOfDomains> still available.











=cut

