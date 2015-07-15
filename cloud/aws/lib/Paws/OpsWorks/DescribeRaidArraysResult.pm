
package Paws::OpsWorks::DescribeRaidArraysResult {
  use Moose;
  has RaidArrays => (is => 'ro', isa => 'ArrayRef[Paws::OpsWorks::RaidArray]');

}

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeRaidArraysResult

=head1 ATTRIBUTES

=head2 RaidArrays => ArrayRef[Paws::OpsWorks::RaidArray]

  

A C<RaidArrays> object that describes the specified RAID arrays.











=cut

1;