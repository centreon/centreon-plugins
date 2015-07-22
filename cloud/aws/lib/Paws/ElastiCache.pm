package Paws::ElastiCache {
  use Moose;
  sub service { 'elasticache' }
  sub version { '2015-02-02' }
  sub flattened_arrays { 0 }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::QueryCaller', 'Paws::Net::XMLResponse';

  
  sub AddTagsToResource {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::AddTagsToResource', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AuthorizeCacheSecurityGroupIngress {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::AuthorizeCacheSecurityGroupIngress', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CopySnapshot {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::CopySnapshot', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateCacheCluster {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::CreateCacheCluster', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateCacheParameterGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::CreateCacheParameterGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateCacheSecurityGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::CreateCacheSecurityGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateCacheSubnetGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::CreateCacheSubnetGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateReplicationGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::CreateReplicationGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateSnapshot {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::CreateSnapshot', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteCacheCluster {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DeleteCacheCluster', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteCacheParameterGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DeleteCacheParameterGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteCacheSecurityGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DeleteCacheSecurityGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteCacheSubnetGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DeleteCacheSubnetGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteReplicationGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DeleteReplicationGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteSnapshot {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DeleteSnapshot', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeCacheClusters {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DescribeCacheClusters', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeCacheEngineVersions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DescribeCacheEngineVersions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeCacheParameterGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DescribeCacheParameterGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeCacheParameters {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DescribeCacheParameters', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeCacheSecurityGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DescribeCacheSecurityGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeCacheSubnetGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DescribeCacheSubnetGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeEngineDefaultParameters {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DescribeEngineDefaultParameters', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeEvents {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DescribeEvents', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeReplicationGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DescribeReplicationGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeReservedCacheNodes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DescribeReservedCacheNodes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeReservedCacheNodesOfferings {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DescribeReservedCacheNodesOfferings', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeSnapshots {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::DescribeSnapshots', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListTagsForResource {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::ListTagsForResource', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyCacheCluster {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::ModifyCacheCluster', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyCacheParameterGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::ModifyCacheParameterGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyCacheSubnetGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::ModifyCacheSubnetGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyReplicationGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::ModifyReplicationGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PurchaseReservedCacheNodesOffering {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::PurchaseReservedCacheNodesOffering', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RebootCacheCluster {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::RebootCacheCluster', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RemoveTagsFromResource {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::RemoveTagsFromResource', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ResetCacheParameterGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::ResetCacheParameterGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RevokeCacheSecurityGroupIngress {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElastiCache::RevokeCacheSecurityGroupIngress', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache - Perl Interface to AWS Amazon ElastiCache

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('ElastiCache')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



Amazon ElastiCache

Amazon ElastiCache is a web service that makes it easier to set up,
operate, and scale a distributed cache in the cloud.

With ElastiCache, customers gain all of the benefits of a
high-performance, in-memory cache with far less of the administrative
burden of launching and managing a distributed cache. The service makes
setup, scaling, and cluster failure handling much simpler than in a
self-managed cache deployment.

In addition, through integration with Amazon CloudWatch, customers get
enhanced visibility into the key performance statistics associated with
their cache and can receive alarms if a part of their cache runs hot.










=head1 METHODS

=head2 AddTagsToResource(ResourceName => Str, Tags => ArrayRef[Paws::ElastiCache::Tag])

Each argument is described in detail in: L<Paws::ElastiCache::AddTagsToResource>

Returns: a L<Paws::ElastiCache::TagListMessage> instance

  

The I<AddTagsToResource> action adds up to 10 cost allocation tags to
the named resource. A I<cost allocation tag> is a key-value pair where
the key and value are case-sensitive. Cost allocation tags can be used
to categorize and track your AWS costs.

When you apply tags to your ElastiCache resources, AWS generates a cost
allocation report as a comma-separated value (CSV) file with your usage
and costs aggregated by your tags. You can apply tags that represent
business categories (such as cost centers, application names, or
owners) to organize your costs across multiple services. For more
information, see Using Cost Allocation Tags in Amazon ElastiCache.











=head2 AuthorizeCacheSecurityGroupIngress(CacheSecurityGroupName => Str, EC2SecurityGroupName => Str, EC2SecurityGroupOwnerId => Str)

Each argument is described in detail in: L<Paws::ElastiCache::AuthorizeCacheSecurityGroupIngress>

Returns: a L<Paws::ElastiCache::AuthorizeCacheSecurityGroupIngressResult> instance

  

The I<AuthorizeCacheSecurityGroupIngress> action allows network ingress
to a cache security group. Applications using ElastiCache must be
running on Amazon EC2, and Amazon EC2 security groups are used as the
authorization mechanism.

You cannot authorize ingress from an Amazon EC2 security group in one
region to an ElastiCache cluster in another region.











=head2 CopySnapshot(SourceSnapshotName => Str, TargetSnapshotName => Str)

Each argument is described in detail in: L<Paws::ElastiCache::CopySnapshot>

Returns: a L<Paws::ElastiCache::CopySnapshotResult> instance

  

The I<CopySnapshot> action makes a copy of an existing snapshot.











=head2 CreateCacheCluster(CacheClusterId => Str, [AutoMinorVersionUpgrade => Bool, AZMode => Str, CacheNodeType => Str, CacheParameterGroupName => Str, CacheSecurityGroupNames => ArrayRef[Str], CacheSubnetGroupName => Str, Engine => Str, EngineVersion => Str, NotificationTopicArn => Str, NumCacheNodes => Int, Port => Int, PreferredAvailabilityZone => Str, PreferredAvailabilityZones => ArrayRef[Str], PreferredMaintenanceWindow => Str, ReplicationGroupId => Str, SecurityGroupIds => ArrayRef[Str], SnapshotArns => ArrayRef[Str], SnapshotName => Str, SnapshotRetentionLimit => Int, SnapshotWindow => Str, Tags => ArrayRef[Paws::ElastiCache::Tag]])

Each argument is described in detail in: L<Paws::ElastiCache::CreateCacheCluster>

Returns: a L<Paws::ElastiCache::CreateCacheClusterResult> instance

  

The I<CreateCacheCluster> action creates a cache cluster. All nodes in
the cache cluster run the same protocol-compliant cache engine
software, either Memcached or Redis.











=head2 CreateCacheParameterGroup(CacheParameterGroupFamily => Str, CacheParameterGroupName => Str, Description => Str)

Each argument is described in detail in: L<Paws::ElastiCache::CreateCacheParameterGroup>

Returns: a L<Paws::ElastiCache::CreateCacheParameterGroupResult> instance

  

The I<CreateCacheParameterGroup> action creates a new cache parameter
group. A cache parameter group is a collection of parameters that you
apply to all of the nodes in a cache cluster.











=head2 CreateCacheSecurityGroup(CacheSecurityGroupName => Str, Description => Str)

Each argument is described in detail in: L<Paws::ElastiCache::CreateCacheSecurityGroup>

Returns: a L<Paws::ElastiCache::CreateCacheSecurityGroupResult> instance

  

The I<CreateCacheSecurityGroup> action creates a new cache security
group. Use a cache security group to control access to one or more
cache clusters.

Cache security groups are only used when you are creating a cache
cluster outside of an Amazon Virtual Private Cloud (VPC). If you are
creating a cache cluster inside of a VPC, use a cache subnet group
instead. For more information, see CreateCacheSubnetGroup.











=head2 CreateCacheSubnetGroup(CacheSubnetGroupDescription => Str, CacheSubnetGroupName => Str, SubnetIds => ArrayRef[Str])

Each argument is described in detail in: L<Paws::ElastiCache::CreateCacheSubnetGroup>

Returns: a L<Paws::ElastiCache::CreateCacheSubnetGroupResult> instance

  

The I<CreateCacheSubnetGroup> action creates a new cache subnet group.

Use this parameter only when you are creating a cluster in an Amazon
Virtual Private Cloud (VPC).











=head2 CreateReplicationGroup(ReplicationGroupDescription => Str, ReplicationGroupId => Str, [AutomaticFailoverEnabled => Bool, AutoMinorVersionUpgrade => Bool, CacheNodeType => Str, CacheParameterGroupName => Str, CacheSecurityGroupNames => ArrayRef[Str], CacheSubnetGroupName => Str, Engine => Str, EngineVersion => Str, NotificationTopicArn => Str, NumCacheClusters => Int, Port => Int, PreferredCacheClusterAZs => ArrayRef[Str], PreferredMaintenanceWindow => Str, PrimaryClusterId => Str, SecurityGroupIds => ArrayRef[Str], SnapshotArns => ArrayRef[Str], SnapshotName => Str, SnapshotRetentionLimit => Int, SnapshotWindow => Str, Tags => ArrayRef[Paws::ElastiCache::Tag]])

Each argument is described in detail in: L<Paws::ElastiCache::CreateReplicationGroup>

Returns: a L<Paws::ElastiCache::CreateReplicationGroupResult> instance

  

The I<CreateReplicationGroup> action creates a replication group. A
replication group is a collection of cache clusters, where one of the
cache clusters is a read/write primary and the others are read-only
replicas. Writes to the primary are automatically propagated to the
replicas.

When you create a replication group, you must specify an existing cache
cluster that is in the primary role. When the replication group has
been successfully created, you can add one or more read replica
replicas to it, up to a total of five read replicas.

B<Note:> This action is valid only for Redis.











=head2 CreateSnapshot(CacheClusterId => Str, SnapshotName => Str)

Each argument is described in detail in: L<Paws::ElastiCache::CreateSnapshot>

Returns: a L<Paws::ElastiCache::CreateSnapshotResult> instance

  

The I<CreateSnapshot> action creates a copy of an entire cache cluster
at a specific moment in time.











=head2 DeleteCacheCluster(CacheClusterId => Str, [FinalSnapshotIdentifier => Str])

Each argument is described in detail in: L<Paws::ElastiCache::DeleteCacheCluster>

Returns: a L<Paws::ElastiCache::DeleteCacheClusterResult> instance

  

The I<DeleteCacheCluster> action deletes a previously provisioned cache
cluster. I<DeleteCacheCluster> deletes all associated cache nodes, node
endpoints and the cache cluster itself. When you receive a successful
response from this action, Amazon ElastiCache immediately begins
deleting the cache cluster; you cannot cancel or revert this action.

This API cannot be used to delete a cache cluster that is the last read
replica of a replication group that has Multi-AZ mode enabled.











=head2 DeleteCacheParameterGroup(CacheParameterGroupName => Str)

Each argument is described in detail in: L<Paws::ElastiCache::DeleteCacheParameterGroup>

Returns: nothing

  

The I<DeleteCacheParameterGroup> action deletes the specified cache
parameter group. You cannot delete a cache parameter group if it is
associated with any cache clusters.











=head2 DeleteCacheSecurityGroup(CacheSecurityGroupName => Str)

Each argument is described in detail in: L<Paws::ElastiCache::DeleteCacheSecurityGroup>

Returns: nothing

  

The I<DeleteCacheSecurityGroup> action deletes a cache security group.

You cannot delete a cache security group if it is associated with any
cache clusters.











=head2 DeleteCacheSubnetGroup(CacheSubnetGroupName => Str)

Each argument is described in detail in: L<Paws::ElastiCache::DeleteCacheSubnetGroup>

Returns: nothing

  

The I<DeleteCacheSubnetGroup> action deletes a cache subnet group.

You cannot delete a cache subnet group if it is associated with any
cache clusters.











=head2 DeleteReplicationGroup(ReplicationGroupId => Str, [FinalSnapshotIdentifier => Str, RetainPrimaryCluster => Bool])

Each argument is described in detail in: L<Paws::ElastiCache::DeleteReplicationGroup>

Returns: a L<Paws::ElastiCache::DeleteReplicationGroupResult> instance

  

The I<DeleteReplicationGroup> action deletes an existing replication
group. By default, this action deletes the entire replication group,
including the primary cluster and all of the read replicas. You can
optionally delete only the read replicas, while retaining the primary
cluster.

When you receive a successful response from this action, Amazon
ElastiCache immediately begins deleting the selected resources; you
cannot cancel or revert this action.











=head2 DeleteSnapshot(SnapshotName => Str)

Each argument is described in detail in: L<Paws::ElastiCache::DeleteSnapshot>

Returns: a L<Paws::ElastiCache::DeleteSnapshotResult> instance

  

The I<DeleteSnapshot> action deletes an existing snapshot. When you
receive a successful response from this action, ElastiCache immediately
begins deleting the snapshot; you cannot cancel or revert this action.











=head2 DescribeCacheClusters([CacheClusterId => Str, Marker => Str, MaxRecords => Int, ShowCacheNodeInfo => Bool])

Each argument is described in detail in: L<Paws::ElastiCache::DescribeCacheClusters>

Returns: a L<Paws::ElastiCache::CacheClusterMessage> instance

  

The I<DescribeCacheClusters> action returns information about all
provisioned cache clusters if no cache cluster identifier is specified,
or about a specific cache cluster if a cache cluster identifier is
supplied.

By default, abbreviated information about the cache clusters(s) will be
returned. You can use the optional I<ShowDetails> flag to retrieve
detailed information about the cache nodes associated with the cache
clusters. These details include the DNS address and port for the cache
node endpoint.

If the cluster is in the CREATING state, only cluster level information
will be displayed until all of the nodes are successfully provisioned.

If the cluster is in the DELETING state, only cluster level information
will be displayed.

If cache nodes are currently being added to the cache cluster, node
endpoint information and creation time for the additional nodes will
not be displayed until they are completely provisioned. When the cache
cluster state is I<available>, the cluster is ready for use.

If cache nodes are currently being removed from the cache cluster, no
endpoint information for the removed nodes is displayed.











=head2 DescribeCacheEngineVersions([CacheParameterGroupFamily => Str, DefaultOnly => Bool, Engine => Str, EngineVersion => Str, Marker => Str, MaxRecords => Int])

Each argument is described in detail in: L<Paws::ElastiCache::DescribeCacheEngineVersions>

Returns: a L<Paws::ElastiCache::CacheEngineVersionMessage> instance

  

The I<DescribeCacheEngineVersions> action returns a list of the
available cache engines and their versions.











=head2 DescribeCacheParameterGroups([CacheParameterGroupName => Str, Marker => Str, MaxRecords => Int])

Each argument is described in detail in: L<Paws::ElastiCache::DescribeCacheParameterGroups>

Returns: a L<Paws::ElastiCache::CacheParameterGroupsMessage> instance

  

The I<DescribeCacheParameterGroups> action returns a list of cache
parameter group descriptions. If a cache parameter group name is
specified, the list will contain only the descriptions for that group.











=head2 DescribeCacheParameters(CacheParameterGroupName => Str, [Marker => Str, MaxRecords => Int, Source => Str])

Each argument is described in detail in: L<Paws::ElastiCache::DescribeCacheParameters>

Returns: a L<Paws::ElastiCache::CacheParameterGroupDetails> instance

  

The I<DescribeCacheParameters> action returns the detailed parameter
list for a particular cache parameter group.











=head2 DescribeCacheSecurityGroups([CacheSecurityGroupName => Str, Marker => Str, MaxRecords => Int])

Each argument is described in detail in: L<Paws::ElastiCache::DescribeCacheSecurityGroups>

Returns: a L<Paws::ElastiCache::CacheSecurityGroupMessage> instance

  

The I<DescribeCacheSecurityGroups> action returns a list of cache
security group descriptions. If a cache security group name is
specified, the list will contain only the description of that group.











=head2 DescribeCacheSubnetGroups([CacheSubnetGroupName => Str, Marker => Str, MaxRecords => Int])

Each argument is described in detail in: L<Paws::ElastiCache::DescribeCacheSubnetGroups>

Returns: a L<Paws::ElastiCache::CacheSubnetGroupMessage> instance

  

The I<DescribeCacheSubnetGroups> action returns a list of cache subnet
group descriptions. If a subnet group name is specified, the list will
contain only the description of that group.











=head2 DescribeEngineDefaultParameters(CacheParameterGroupFamily => Str, [Marker => Str, MaxRecords => Int])

Each argument is described in detail in: L<Paws::ElastiCache::DescribeEngineDefaultParameters>

Returns: a L<Paws::ElastiCache::DescribeEngineDefaultParametersResult> instance

  

The I<DescribeEngineDefaultParameters> action returns the default
engine and system parameter information for the specified cache engine.











=head2 DescribeEvents([Duration => Int, EndTime => Str, Marker => Str, MaxRecords => Int, SourceIdentifier => Str, SourceType => Str, StartTime => Str])

Each argument is described in detail in: L<Paws::ElastiCache::DescribeEvents>

Returns: a L<Paws::ElastiCache::EventsMessage> instance

  

The I<DescribeEvents> action returns events related to cache clusters,
cache security groups, and cache parameter groups. You can obtain
events specific to a particular cache cluster, cache security group, or
cache parameter group by providing the name as a parameter.

By default, only the events occurring within the last hour are
returned; however, you can retrieve up to 14 days' worth of events if
necessary.











=head2 DescribeReplicationGroups([Marker => Str, MaxRecords => Int, ReplicationGroupId => Str])

Each argument is described in detail in: L<Paws::ElastiCache::DescribeReplicationGroups>

Returns: a L<Paws::ElastiCache::ReplicationGroupMessage> instance

  

The I<DescribeReplicationGroups> action returns information about a
particular replication group. If no identifier is specified,
I<DescribeReplicationGroups> returns information about all replication
groups.











=head2 DescribeReservedCacheNodes([CacheNodeType => Str, Duration => Str, Marker => Str, MaxRecords => Int, OfferingType => Str, ProductDescription => Str, ReservedCacheNodeId => Str, ReservedCacheNodesOfferingId => Str])

Each argument is described in detail in: L<Paws::ElastiCache::DescribeReservedCacheNodes>

Returns: a L<Paws::ElastiCache::ReservedCacheNodeMessage> instance

  

The I<DescribeReservedCacheNodes> action returns information about
reserved cache nodes for this account, or about a specified reserved
cache node.











=head2 DescribeReservedCacheNodesOfferings([CacheNodeType => Str, Duration => Str, Marker => Str, MaxRecords => Int, OfferingType => Str, ProductDescription => Str, ReservedCacheNodesOfferingId => Str])

Each argument is described in detail in: L<Paws::ElastiCache::DescribeReservedCacheNodesOfferings>

Returns: a L<Paws::ElastiCache::ReservedCacheNodesOfferingMessage> instance

  

The I<DescribeReservedCacheNodesOfferings> action lists available
reserved cache node offerings.











=head2 DescribeSnapshots([CacheClusterId => Str, Marker => Str, MaxRecords => Int, SnapshotName => Str, SnapshotSource => Str])

Each argument is described in detail in: L<Paws::ElastiCache::DescribeSnapshots>

Returns: a L<Paws::ElastiCache::DescribeSnapshotsListMessage> instance

  

The I<DescribeSnapshots> action returns information about cache cluster
snapshots. By default, I<DescribeSnapshots> lists all of your
snapshots; it can optionally describe a single snapshot, or just the
snapshots associated with a particular cache cluster.











=head2 ListTagsForResource(ResourceName => Str)

Each argument is described in detail in: L<Paws::ElastiCache::ListTagsForResource>

Returns: a L<Paws::ElastiCache::TagListMessage> instance

  

The I<ListTagsForResource> action lists all cost allocation tags
currently on the named resource. A I<cost allocation tag> is a
key-value pair where the key is case-sensitive and the value is
optional. Cost allocation tags can be used to categorize and track your
AWS costs.

You can have a maximum of 10 cost allocation tags on an ElastiCache
resource. For more information, see Using Cost Allocation Tags in
Amazon ElastiCache.











=head2 ModifyCacheCluster(CacheClusterId => Str, [ApplyImmediately => Bool, AutoMinorVersionUpgrade => Bool, AZMode => Str, CacheNodeIdsToRemove => ArrayRef[Str], CacheParameterGroupName => Str, CacheSecurityGroupNames => ArrayRef[Str], EngineVersion => Str, NewAvailabilityZones => ArrayRef[Str], NotificationTopicArn => Str, NotificationTopicStatus => Str, NumCacheNodes => Int, PreferredMaintenanceWindow => Str, SecurityGroupIds => ArrayRef[Str], SnapshotRetentionLimit => Int, SnapshotWindow => Str])

Each argument is described in detail in: L<Paws::ElastiCache::ModifyCacheCluster>

Returns: a L<Paws::ElastiCache::ModifyCacheClusterResult> instance

  

The I<ModifyCacheCluster> action modifies the settings for a cache
cluster. You can use this action to change one or more cluster
configuration parameters by specifying the parameters and the new
values.











=head2 ModifyCacheParameterGroup(CacheParameterGroupName => Str, ParameterNameValues => ArrayRef[Paws::ElastiCache::ParameterNameValue])

Each argument is described in detail in: L<Paws::ElastiCache::ModifyCacheParameterGroup>

Returns: a L<Paws::ElastiCache::CacheParameterGroupNameMessage> instance

  

The I<ModifyCacheParameterGroup> action modifies the parameters of a
cache parameter group. You can modify up to 20 parameters in a single
request by submitting a list parameter name and value pairs.











=head2 ModifyCacheSubnetGroup(CacheSubnetGroupName => Str, [CacheSubnetGroupDescription => Str, SubnetIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::ElastiCache::ModifyCacheSubnetGroup>

Returns: a L<Paws::ElastiCache::ModifyCacheSubnetGroupResult> instance

  

The I<ModifyCacheSubnetGroup> action modifies an existing cache subnet
group.











=head2 ModifyReplicationGroup(ReplicationGroupId => Str, [ApplyImmediately => Bool, AutomaticFailoverEnabled => Bool, AutoMinorVersionUpgrade => Bool, CacheParameterGroupName => Str, CacheSecurityGroupNames => ArrayRef[Str], EngineVersion => Str, NotificationTopicArn => Str, NotificationTopicStatus => Str, PreferredMaintenanceWindow => Str, PrimaryClusterId => Str, ReplicationGroupDescription => Str, SecurityGroupIds => ArrayRef[Str], SnapshotRetentionLimit => Int, SnapshottingClusterId => Str, SnapshotWindow => Str])

Each argument is described in detail in: L<Paws::ElastiCache::ModifyReplicationGroup>

Returns: a L<Paws::ElastiCache::ModifyReplicationGroupResult> instance

  

The I<ModifyReplicationGroup> action modifies the settings for a
replication group.











=head2 PurchaseReservedCacheNodesOffering(ReservedCacheNodesOfferingId => Str, [CacheNodeCount => Int, ReservedCacheNodeId => Str])

Each argument is described in detail in: L<Paws::ElastiCache::PurchaseReservedCacheNodesOffering>

Returns: a L<Paws::ElastiCache::PurchaseReservedCacheNodesOfferingResult> instance

  

The I<PurchaseReservedCacheNodesOffering> action allows you to purchase
a reserved cache node offering.











=head2 RebootCacheCluster(CacheClusterId => Str, CacheNodeIdsToReboot => ArrayRef[Str])

Each argument is described in detail in: L<Paws::ElastiCache::RebootCacheCluster>

Returns: a L<Paws::ElastiCache::RebootCacheClusterResult> instance

  

The I<RebootCacheCluster> action reboots some, or all, of the cache
nodes within a provisioned cache cluster. This API will apply any
modified cache parameter groups to the cache cluster. The reboot action
takes place as soon as possible, and results in a momentary outage to
the cache cluster. During the reboot, the cache cluster status is set
to REBOOTING.

The reboot causes the contents of the cache (for each cache node being
rebooted) to be lost.

When the reboot is complete, a cache cluster event is created.











=head2 RemoveTagsFromResource(ResourceName => Str, TagKeys => ArrayRef[Str])

Each argument is described in detail in: L<Paws::ElastiCache::RemoveTagsFromResource>

Returns: a L<Paws::ElastiCache::TagListMessage> instance

  

The I<RemoveTagsFromResource> action removes the tags identified by the
C<TagKeys> list from the named resource.











=head2 ResetCacheParameterGroup(CacheParameterGroupName => Str, ParameterNameValues => ArrayRef[Paws::ElastiCache::ParameterNameValue], [ResetAllParameters => Bool])

Each argument is described in detail in: L<Paws::ElastiCache::ResetCacheParameterGroup>

Returns: a L<Paws::ElastiCache::CacheParameterGroupNameMessage> instance

  

The I<ResetCacheParameterGroup> action modifies the parameters of a
cache parameter group to the engine or system default value. You can
reset specific parameters by submitting a list of parameter names. To
reset the entire cache parameter group, specify the
I<ResetAllParameters> and I<CacheParameterGroupName> parameters.











=head2 RevokeCacheSecurityGroupIngress(CacheSecurityGroupName => Str, EC2SecurityGroupName => Str, EC2SecurityGroupOwnerId => Str)

Each argument is described in detail in: L<Paws::ElastiCache::RevokeCacheSecurityGroupIngress>

Returns: a L<Paws::ElastiCache::RevokeCacheSecurityGroupIngressResult> instance

  

The I<RevokeCacheSecurityGroupIngress> action revokes ingress from a
cache security group. Use this action to disallow access from an Amazon
EC2 security group that had been previously authorized.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

