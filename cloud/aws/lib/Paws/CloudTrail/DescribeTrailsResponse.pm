
package Paws::CloudTrail::DescribeTrailsResponse {
  use Moose;
  has trailList => (is => 'ro', isa => 'ArrayRef[Paws::CloudTrail::Trail]');

}

### main pod documentation begin ###

=head1 NAME

Paws::CloudTrail::DescribeTrailsResponse

=head1 ATTRIBUTES

=head2 trailList => ArrayRef[Paws::CloudTrail::Trail]

  

The list of trails.











=cut

1;