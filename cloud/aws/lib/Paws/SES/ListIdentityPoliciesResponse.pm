
package Paws::SES::ListIdentityPoliciesResponse {
  use Moose;
  has PolicyNames => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::ListIdentityPoliciesResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> PolicyNames => ArrayRef[Str]

  

A list of names of policies that apply to the specified identity.











=cut

