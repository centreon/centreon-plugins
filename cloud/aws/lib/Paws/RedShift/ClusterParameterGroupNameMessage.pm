
package Paws::RedShift::ClusterParameterGroupNameMessage {
  use Moose;
  has ParameterGroupName => (is => 'ro', isa => 'Str');
  has ParameterGroupStatus => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::ClusterParameterGroupNameMessage

=head1 ATTRIBUTES

=head2 ParameterGroupName => Str

  

The name of the cluster parameter group.









=head2 ParameterGroupStatus => Str

  

The status of the parameter group. For example, if you made a change to
a parameter group name-value pair, then the change could be pending a
reboot of an associated cluster.











=cut

