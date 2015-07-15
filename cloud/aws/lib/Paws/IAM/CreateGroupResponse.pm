
package Paws::IAM::CreateGroupResponse {
  use Moose;
  has Group => (is => 'ro', isa => 'Paws::IAM::Group', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::CreateGroupResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> Group => Paws::IAM::Group

  

Information about the group.











=cut

