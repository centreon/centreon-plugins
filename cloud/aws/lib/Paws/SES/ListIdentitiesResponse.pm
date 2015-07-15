
package Paws::SES::ListIdentitiesResponse {
  use Moose;
  has Identities => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has NextToken => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::ListIdentitiesResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> Identities => ArrayRef[Str]

  

A list of identities.









=head2 NextToken => Str

  

The token used for pagination.











=cut

