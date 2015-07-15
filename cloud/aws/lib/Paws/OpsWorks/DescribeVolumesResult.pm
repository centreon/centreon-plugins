
package Paws::OpsWorks::DescribeVolumesResult {
  use Moose;
  has Volumes => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::Volume]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeVolumesResult

=head1 ATTRIBUTES

=head2 Volumes => ArrayRef[Paws::OpsWorks::Volume]

  

An array of volume IDs.











=cut

1;