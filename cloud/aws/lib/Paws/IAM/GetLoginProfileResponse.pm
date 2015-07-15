
package Paws::IAM::GetLoginProfileResponse {
  use Moose;
  has LoginProfile => (is => 'ro', isa => 'Paws::IAM::LoginProfile', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::GetLoginProfileResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> LoginProfile => Paws::IAM::LoginProfile

  

The user name and password create date for the user.











=cut

