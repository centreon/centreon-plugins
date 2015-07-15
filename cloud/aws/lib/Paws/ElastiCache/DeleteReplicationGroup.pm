
package Paws::ElastiCache::DeleteReplicationGroup {
  use Moose;
  has FinalSnapshotIdentifier => (is => 'ro', isa => 'Str');
  has ReplicationGroupId => (is => 'ro', isa => 'Str', required => 1);
  has RetainPrimaryCluster => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DeleteReplicationGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::DeleteReplicationGroupResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DeleteReplicationGroupResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::DeleteReplicationGroup - Arguments for method DeleteReplicationGroup on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method DeleteReplicationGroup on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method DeleteReplicationGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DeleteReplicationGroup.

As an example:

  $service_obj->DeleteReplicationGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 FinalSnapshotIdentifier => Str

  

The name of a final node group snapshot. ElastiCache creates the
snapshot from the primary node in the cluster, rather than one of the
replicas; this is to ensure that it captures the freshest data. After
the final snapshot is taken, the cluster is immediately deleted.










=head2 B<REQUIRED> ReplicationGroupId => Str

  

The identifier for the cluster to be deleted. This parameter is not
case sensitive.










=head2 RetainPrimaryCluster => Bool

  

If set to I<true>, all of the read replicas will be deleted, but the
primary node will be retained.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DeleteReplicationGroup in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

