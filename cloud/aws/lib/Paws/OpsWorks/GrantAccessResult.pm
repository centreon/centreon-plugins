
package Paws::OpsWorks::GrantAccessResult {
  use Moose;
  has TemporaryCredential => (is => 'ro', isa => 'Paws::OpsWorks::TemporaryCredential');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::GrantAccessResult

=head1 ATTRIBUTES

=head2 TemporaryCredential => Paws::OpsWorks::TemporaryCredential

  

A C<TemporaryCredential> object that contains the data needed to log in
to the instance by RDP clients, such as the Microsoft Remote Desktop
Connection.











=cut

1;