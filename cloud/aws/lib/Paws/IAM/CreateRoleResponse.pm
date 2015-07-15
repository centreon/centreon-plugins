
package Paws::IAM::CreateRoleResponse {
  use Moose;
  has Role => (is => 'ro', isa => 'Paws::IAM::Role', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::CreateRoleResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> Role => Paws::IAM::Role

  

Information about the role.











=cut

