
package Paws::SNS::ListPlatformApplicationsResponse {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has PlatformApplications => (is => 'ro', isa => 'ArrayRef[Paws::SNS::PlatformApplication]');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::ListPlatformApplicationsResponse

=head1 ATTRIBUTES

=head2 NextToken => Str

  

NextToken string is returned when calling ListPlatformApplications
action if additional records are available after the first page
results.









=head2 PlatformApplications => ArrayRef[Paws::SNS::PlatformApplication]

  

Platform applications returned when calling ListPlatformApplications
action.











=cut

