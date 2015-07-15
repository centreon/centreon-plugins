
package Paws::ElastiCache::CreateCacheCluster {
  use Moose;
  has AutoMinorVersionUpgrade => (is => 'ro', isa => 'Bool');
  has AZMode => (is => 'ro', isa => 'Str');
  has CacheClusterId => (is => 'ro', isa => 'Str', required => 1);
  has CacheNodeType => (is => 'ro', isa => 'Str');
  has CacheParameterGroupName => (is => 'ro', isa => 'Str');
  has CacheSecurityGroupNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has CacheSubnetGroupName => (is => 'ro', isa => 'Str');
  has Engine => (is => 'ro', isa => 'Str');
  has EngineVersion => (is => 'ro', isa => 'Str');
  has NotificationTopicArn => (is => 'ro', isa => 'Str');
  has NumCacheNodes => (is => 'ro', isa => 'Int');
  has Port => (is => 'ro', isa => 'Int');
  has PreferredAvailabilityZone => (is => 'ro', isa => 'Str');
  has PreferredAvailabilityZones => (is => 'ro', isa => 'ArrayRef[Str]');
  has PreferredMaintenanceWindow => (is => 'ro', isa => 'Str');
  has ReplicationGroupId => (is => 'ro', isa => 'Str');
  has SecurityGroupIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has SnapshotArns => (is => 'ro', isa => 'ArrayRef[Str]');
  has SnapshotName => (is => 'ro', isa => 'Str');
  has SnapshotRetentionLimit => (is => 'ro', isa => 'Int');
  has SnapshotWindow => (is => 'ro', isa => 'Str');
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::ElastiCache::Tag]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateCacheCluster');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::CreateCacheClusterResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateCacheClusterResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::CreateCacheCluster - Arguments for method CreateCacheCluster on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateCacheCluster on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method CreateCacheCluster.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateCacheCluster.

As an example:

  $service_obj->CreateCacheCluster(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AutoMinorVersionUpgrade => Bool

  

This parameter is currently disabled.










=head2 AZMode => Str

  

Specifies whether the nodes in this Memcached node group are created in
a single Availability Zone or created across multiple Availability
Zones in the cluster's region.

This parameter is only supported for Memcached cache clusters.

If the C<AZMode> and C<PreferredAvailabilityZones> are not specified,
ElastiCache assumes C<single-az> mode.










=head2 B<REQUIRED> CacheClusterId => Str

  

The node group identifier. This parameter is stored as a lowercase
string.

Constraints:

=over

=item * A name must contain from 1 to 20 alphanumeric characters or
hyphens.

=item * The first character must be a letter.

=item * A name cannot end with a hyphen or contain two consecutive
hyphens.

=back










=head2 CacheNodeType => Str

  

The compute and memory capacity of the nodes in the node group.

Valid node types are as follows:

=over

=item * General purpose:

=over

=item * Current generation: C<cache.t2.micro>, C<cache.t2.small>,
C<cache.t2.medium>, C<cache.m3.medium>, C<cache.m3.large>,
C<cache.m3.xlarge>, C<cache.m3.2xlarge>

=item * Previous generation: C<cache.t1.micro>, C<cache.m1.small>,
C<cache.m1.medium>, C<cache.m1.large>, C<cache.m1.xlarge>

=back

=item * Compute optimized: C<cache.c1.xlarge>

=item * Memory optimized

=over

=item * Current generation: C<cache.r3.large>, C<cache.r3.xlarge>,
C<cache.r3.2xlarge>, C<cache.r3.4xlarge>, C<cache.r3.8xlarge>

=item * Previous generation: C<cache.m2.xlarge>, C<cache.m2.2xlarge>,
C<cache.m2.4xlarge>

=back

=back

B<Notes:>

=over

=item * All t2 instances are created in an Amazon Virtual Private Cloud
(VPC).

=item * Redis backup/restore is not supported for t2 instances.

=item * Redis Append-only files (AOF) functionality is not supported
for t1 or t2 instances.

=back

For a complete listing of cache node types and specifications, see
Amazon ElastiCache Product Features and Details and Cache Node
Type-Specific Parameters for Memcached or Cache Node Type-Specific
Parameters for Redis.










=head2 CacheParameterGroupName => Str

  

The name of the parameter group to associate with this cache cluster.
If this argument is omitted, the default parameter group for the
specified engine is used.










=head2 CacheSecurityGroupNames => ArrayRef[Str]

  

A list of security group names to associate with this cache cluster.

Use this parameter only when you are creating a cache cluster outside
of an Amazon Virtual Private Cloud (VPC).










=head2 CacheSubnetGroupName => Str

  

The name of the subnet group to be used for the cache cluster.

Use this parameter only when you are creating a cache cluster in an
Amazon Virtual Private Cloud (VPC).










=head2 Engine => Str

  

The name of the cache engine to be used for this cache cluster.

Valid values for this parameter are:

C<memcached> | C<redis>










=head2 EngineVersion => Str

  

The version number of the cache engine to be used for this cache
cluster. To view the supported cache engine versions, use the
I<DescribeCacheEngineVersions> action.










=head2 NotificationTopicArn => Str

  

The Amazon Resource Name (ARN) of the Amazon Simple Notification
Service (SNS) topic to which notifications will be sent.

The Amazon SNS topic owner must be the same as the cache cluster owner.










=head2 NumCacheNodes => Int

  

The initial number of cache nodes that the cache cluster will have.

For clusters running Redis, this value must be 1. For clusters running
Memcached, this value must be between 1 and 20.

If you need more than 20 nodes for your Memcached cluster, please fill
out the ElastiCache Limit Increase Request form at
http://aws.amazon.com/contact-us/elasticache-node-limit-request/.










=head2 Port => Int

  

The port number on which each of the cache nodes will accept
connections.










=head2 PreferredAvailabilityZone => Str

  

The EC2 Availability Zone in which the cache cluster will be created.

All nodes belonging to this Memcached cache cluster are placed in the
preferred Availability Zone. If you want to create your nodes across
multiple Availability Zones, use C<PreferredAvailabilityZones>.

Default: System chosen Availability Zone.










=head2 PreferredAvailabilityZones => ArrayRef[Str]

  

A list of the Availability Zones in which cache nodes will be created.
The order of the zones in the list is not important.

This option is only supported on Memcached.

If you are creating your cache cluster in an Amazon VPC (recommended)
you can only locate nodes in Availability Zones that are associated
with the subnets in the selected subnet group.

The number of Availability Zones listed must equal the value of
C<NumCacheNodes>.

If you want all the nodes in the same Availability Zone, use
C<PreferredAvailabilityZone> instead, or repeat the Availability Zone
multiple times in the list.

Default: System chosen Availability Zones.

Example: One Memcached node in each of three different Availability
Zones:
C<PreferredAvailabilityZones.member.1=us-west-2a&PreferredAvailabilityZones.member.2=us-west-2b&PreferredAvailabilityZones.member.3=us-west-2c>

Example: All three Memcached nodes in one Availability Zone:
C<PreferredAvailabilityZones.member.1=us-west-2a&PreferredAvailabilityZones.member.2=us-west-2a&PreferredAvailabilityZones.member.3=us-west-2a>










=head2 PreferredMaintenanceWindow => Str

  

Specifies the weekly time range during which maintenance on the cache
cluster is performed. It is specified as a range in the format
ddd:hh24:mi-ddd:hh24:mi (24H Clock UTC). The minimum maintenance window
is a 60 minute period. Valid values for C<ddd> are:

=over

=item * C<sun>

=item * C<mon>

=item * C<tue>

=item * C<wed>

=item * C<thu>

=item * C<fri>

=item * C<sat>

=back

Example: C<sun:05:00-sun:09:00>










=head2 ReplicationGroupId => Str

  

The ID of the replication group to which this cache cluster should
belong. If this parameter is specified, the cache cluster will be added
to the specified replication group as a read replica; otherwise, the
cache cluster will be a standalone primary that is not part of any
replication group.

If the specified replication group is Multi-AZ enabled and the
availability zone is not specified, the cache cluster will be created
in availability zones that provide the best spread of read replicas
across availability zones.

B<Note:> This parameter is only valid if the C<Engine> parameter is
C<redis>.










=head2 SecurityGroupIds => ArrayRef[Str]

  

One or more VPC security groups associated with the cache cluster.

Use this parameter only when you are creating a cache cluster in an
Amazon Virtual Private Cloud (VPC).










=head2 SnapshotArns => ArrayRef[Str]

  

A single-element string list containing an Amazon Resource Name (ARN)
that uniquely identifies a Redis RDB snapshot file stored in Amazon S3.
The snapshot file will be used to populate the node group. The Amazon
S3 object name in the ARN cannot contain any commas.

B<Note:> This parameter is only valid if the C<Engine> parameter is
C<redis>.

Example of an Amazon S3 ARN: C<arn:aws:s3:::my_bucket/snapshot1.rdb>










=head2 SnapshotName => Str

  

The name of a snapshot from which to restore data into the new node
group. The snapshot status changes to C<restoring> while the new node
group is being created.

B<Note:> This parameter is only valid if the C<Engine> parameter is
C<redis>.










=head2 SnapshotRetentionLimit => Int

  

The number of days for which ElastiCache will retain automatic
snapshots before deleting them. For example, if you set
C<SnapshotRetentionLimit> to 5, then a snapshot that was taken today
will be retained for 5 days before being deleted.

B<Note:> This parameter is only valid if the C<Engine> parameter is
C<redis>.

Default: 0 (i.e., automatic backups are disabled for this cache
cluster).










=head2 SnapshotWindow => Str

  

The daily time range (in UTC) during which ElastiCache will begin
taking a daily snapshot of your node group.

Example: C<05:00-09:00>

If you do not specify this parameter, then ElastiCache will
automatically choose an appropriate time range.

B<Note:> This parameter is only valid if the C<Engine> parameter is
C<redis>.










=head2 Tags => ArrayRef[Paws::ElastiCache::Tag]

  

A list of cost allocation tags to be added to this resource. A tag is a
key-value pair. A tag key must be accompanied by a tag value.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateCacheCluster in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

