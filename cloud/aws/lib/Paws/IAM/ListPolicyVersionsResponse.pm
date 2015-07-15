
package Paws::IAM::ListPolicyVersionsResponse {
  use Moose;
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has Marker => (is => 'ro', isa => 'Str');
  has Versions => (is => 'ro', isa => 'ArrayRef[Paws::IAM::PolicyVersion]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::ListPolicyVersionsResponse

=head1 ATTRIBUTES

=head2 IsTruncated => Bool

  

A flag that indicates whether there are more policy versions to list.
If your results were truncated, you can make a subsequent pagination
request using the C<Marker> request parameter to retrieve more policy
versions in the list.









=head2 Marker => Str

  

If C<IsTruncated> is C<true>, this element is present and contains the
value to use for the C<Marker> parameter in a subsequent pagination
request.









=head2 Versions => ArrayRef[Paws::IAM::PolicyVersion]

  

A list of policy versions.

For more information about managed policy versions, see Versioning for
Managed Policies in the I<Using IAM> guide.











=cut

