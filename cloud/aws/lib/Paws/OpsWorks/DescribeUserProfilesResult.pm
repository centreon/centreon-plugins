
package Paws::OpsWorks::DescribeUserProfilesResult {
  use Moose;
  has UserProfiles => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::UserProfile]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeUserProfilesResult

=head1 ATTRIBUTES

=head2 UserProfiles => ArrayRef[Paws::OpsWorks::UserProfile]

  

A C<Users> object that describes the specified users.











=cut

1;