
package Paws::IAM::GetAccountPasswordPolicyResponse {
  use Moose;
  has PasswordPolicy => (is => 'ro', isa => 'Paws::IAM::PasswordPolicy', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::GetAccountPasswordPolicyResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> PasswordPolicy => Paws::IAM::PasswordPolicy

  


=cut

