
package Paws::IAM::ListInstanceProfilesForRoleResponse {
  use Moose;
  has InstanceProfiles => (is => 'ro', isa => 'ArrayRef[Paws::IAM::InstanceProfile]', required => 1);
  has IsTruncated => (is => 'ro', isa => 'Bool');
  has Marker => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::ListInstanceProfilesForRoleResponse

=head1 ATTRIBUTES

=head2 B<REQUIRED> InstanceProfiles => ArrayRef[Paws::IAM::InstanceProfile]

  

A list of instance profiles.









=head2 IsTruncated => Bool

  

A flag that indicates whether there are more instance profiles to list.
If your results were truncated, you can make a subsequent pagination
request using the C<Marker> request parameter to retrieve more instance
profiles in the list.









=head2 Marker => Str

  

If C<IsTruncated> is C<true>, this element is present and contains the
value to use for the C<Marker> parameter in a subsequent pagination
request.











=cut

