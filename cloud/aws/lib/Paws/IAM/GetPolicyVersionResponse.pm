
package Paws::IAM::GetPolicyVersionResponse {
  use Moose;
  has PolicyVersion => (is => 'ro', isa => 'Paws::IAM::PolicyVersion');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::GetPolicyVersionResponse

=head1 ATTRIBUTES

=head2 PolicyVersion => Paws::IAM::PolicyVersion

  

Information about the policy version.

For more information about managed policy versions, see Versioning for
Managed Policies in the I<Using IAM> guide.











=cut

