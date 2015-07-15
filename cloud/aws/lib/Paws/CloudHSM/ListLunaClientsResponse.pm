
package Paws::CloudHSM::ListLunaClientsResponse {
  use Moose;
  has ClientList => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has NextToken => (is => 'ro', isa => 'Str');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudHSM::ListLunaClientsResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> ClientList => ArrayRef[Str]

  

The list of clients.









=head2 NextToken => Str

  

If not null, more results are available. Pass this to ListLunaClients
to retrieve the next set of items.











=cut

1;