
package Paws::ElastiCache::ModifyCacheCluster {
  use Moose;
  has ApplyImmediately => (is => 'ro', isa => 'Bool');
  has AutoMinorVersionUpgrade => (is => 'ro', isa => 'Bool');
  has AZMode => (is => 'ro', isa => 'Str');
  has CacheClusterId => (is => 'ro', isa => 'Str', required => 1);
  has CacheNodeIdsToRemove => (is => 'ro', isa => 'ArrayRef[Str]');
  has CacheParameterGroupName => (is => 'ro', isa => 'Str');
  has CacheSecurityGroupNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has EngineVersion => (is => 'ro', isa => 'Str');
  has NewAvailabilityZones => (is => 'ro', isa => 'ArrayRef[Str]');
  has NotificationTopicArn => (is => 'ro', isa => 'Str');
  has NotificationTopicStatus => (is => 'ro', isa => 'Str');
  has NumCacheNodes => (is => 'ro', isa => 'Int');
  has PreferredMaintenanceWindow => (is => 'ro', isa => 'Str');
  has SecurityGroupIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has SnapshotRetentionLimit => (is => 'ro', isa => 'Int');
  has SnapshotWindow => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyCacheCluster');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::ModifyCacheClusterResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ModifyCacheClusterResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::ModifyCacheCluster - Arguments for method ModifyCacheCluster on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyCacheCluster on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method ModifyCacheCluster.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyCacheCluster.

As an example:

  $service_obj->ModifyCacheCluster(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ApplyImmediately => Bool

  

If C<true>, this parameter causes the modifications in this request and
any pending modifications to be applied, asynchronously and as soon as
possible, regardless of the I<PreferredMaintenanceWindow> setting for
the cache cluster.

If C<false>, then changes to the cache cluster are applied on the next
maintenance reboot, or the next failure reboot, whichever occurs first.

If you perform a C<ModifyCacheCluster> before a pending modification is
applied, the pending modification is replaced by the newer
modification.

Valid values: C<true> | C<false>

Default: C<false>










=head2 AutoMinorVersionUpgrade => Bool

  

This parameter is currently disabled.










=head2 AZMode => Str

  

Specifies whether the new nodes in this Memcached cache cluster are all
created in a single Availability Zone or created across multiple
Availability Zones.

Valid values: C<single-az> | C<cross-az>.

This option is only supported for Memcached cache clusters.

You cannot specify C<single-az> if the Memcached cache cluster already
has cache nodes in different Availability Zones. If C<cross-az> is
specified, existing Memcached nodes remain in their current
Availability Zone.

Only newly created nodes will be located in different Availability
Zones. For instructions on how to move existing Memcached nodes to
different Availability Zones, see the B<Availability Zone
Considerations> section of Cache Node Considerations for Memcached.










=head2 B<REQUIRED> CacheClusterId => Str

  

The cache cluster identifier. This value is stored as a lowercase
string.










=head2 CacheNodeIdsToRemove => ArrayRef[Str]

  

A list of cache node IDs to be removed. A node ID is a numeric
identifier (0001, 0002, etc.). This parameter is only valid when
I<NumCacheNodes> is less than the existing number of cache nodes. The
number of cache node IDs supplied in this parameter must match the
difference between the existing number of cache nodes in the cluster or
pending cache nodes, whichever is greater, and the value of
I<NumCacheNodes> in the request.

For example: If you have 3 active cache nodes, 7 pending cache nodes,
and the number of cache nodes in this C<ModifyCacheCluser> call is 5,
you must list 2 (7 - 5) cache node IDs to remove.










=head2 CacheParameterGroupName => Str

  

The name of the cache parameter group to apply to this cache cluster.
This change is asynchronously applied as soon as possible for
parameters when the I<ApplyImmediately> parameter is specified as
I<true> for this request.










=head2 CacheSecurityGroupNames => ArrayRef[Str]

  

A list of cache security group names to authorize on this cache
cluster. This change is asynchronously applied as soon as possible.

This parameter can be used only with clusters that are created outside
of an Amazon Virtual Private Cloud (VPC).

Constraints: Must contain no more than 255 alphanumeric characters.
Must not be "Default".










=head2 EngineVersion => Str

  

The upgraded version of the cache engine to be run on the cache nodes.










=head2 NewAvailabilityZones => ArrayRef[Str]

  

The list of Availability Zones where the new Memcached cache nodes will
be created.

This parameter is only valid when I<NumCacheNodes> in the request is
greater than the sum of the number of active cache nodes and the number
of cache nodes pending creation (which may be zero). The number of
Availability Zones supplied in this list must match the cache nodes
being added in this request.

This option is only supported on Memcached clusters.

Scenarios:

=over

=item * B<Scenario 1:> You have 3 active nodes and wish to add 2 nodes.

Specify C<NumCacheNodes=5> (3 + 2) and optionally specify two
Availability Zones for the two new nodes.

=item * B<Scenario 2:> You have 3 active nodes and 2 nodes pending
creation (from the scenario 1 call) and want to add 1 more node.

Specify C<NumCacheNodes=6> ((3 + 2) + 1)

and optionally specify an Availability Zone for the new node.

=item * B<Scenario 3:> You want to cancel all pending actions.

Specify C<NumCacheNodes=3> to cancel all pending actions.

=back

The Availability Zone placement of nodes pending creation cannot be
modified. If you wish to cancel any nodes pending creation, add 0 nodes
by setting C<NumCacheNodes> to the number of current nodes.

If C<cross-az> is specified, existing Memcached nodes remain in their
current Availability Zone. Only newly created nodes can be located in
different Availability Zones. For guidance on how to move existing
Memcached nodes to different Availability Zones, see the B<Availability
Zone Considerations> section of Cache Node Considerations for
Memcached.

B<Impact of new add/remove requests upon pending requests>

Scenarios

Pending action

New Request

Results

Scenario-1

Delete

Delete

The new delete, pending or immediate, replaces the pending delete.

Scenario-2

Delete

Create

The new create, pending or immediate, replaces the pending delete.

Scenario-3

Create

Delete

The new delete, pending or immediate, replaces the pending create.

Scenario-4

Create

Create

The new create is added to the pending create.

B<Important:>

If the new create request is B<Apply Immediately - Yes>, all creates
are performed immediately. If the new create request is B<Apply
Immediately - No>, all creates are pending.

Example:
C<NewAvailabilityZones.member.1=us-west-2a&NewAvailabilityZones.member.2=us-west-2b&NewAvailabilityZones.member.3=us-west-2c>










=head2 NotificationTopicArn => Str

  

The Amazon Resource Name (ARN) of the Amazon SNS topic to which
notifications will be sent.

The Amazon SNS topic owner must be same as the cache cluster owner.










=head2 NotificationTopicStatus => Str

  

The status of the Amazon SNS notification topic. Notifications are sent
only if the status is I<active>.

Valid values: C<active> | C<inactive>










=head2 NumCacheNodes => Int

  

The number of cache nodes that the cache cluster should have. If the
value for C<NumCacheNodes> is greater than the sum of the number of
current cache nodes and the number of cache nodes pending creation
(which may be zero), then more nodes will be added. If the value is
less than the number of existing cache nodes, then nodes will be
removed. If the value is equal to the number of current cache nodes,
then any pending add or remove requests are canceled.

If you are removing cache nodes, you must use the
C<CacheNodeIdsToRemove> parameter to provide the IDs of the specific
cache nodes to remove.

For clusters running Redis, this value must be 1. For clusters running
Memcached, this value must be between 1 and 20.

B<Note:>

Adding or removing Memcached cache nodes can be applied immediately or
as a pending action. See C<ApplyImmediately>.

A pending action to modify the number of cache nodes in a cluster
during its maintenance window, whether by adding or removing nodes in
accordance with the scale out architecture, is not queued. The
customer's latest request to add or remove nodes to the cluster
overrides any previous pending actions to modify the number of cache
nodes in the cluster. For example, a request to remove 2 nodes would
override a previous pending action to remove 3 nodes. Similarly, a
request to add 2 nodes would override a previous pending action to
remove 3 nodes and vice versa. As Memcached cache nodes may now be
provisioned in different Availability Zones with flexible cache node
placement, a request to add nodes does not automatically override a
previous pending action to add nodes. The customer can modify the
previous pending action to add more nodes or explicitly cancel the
pending request and retry the new request. To cancel pending actions to
modify the number of cache nodes in a cluster, use the
C<ModifyCacheCluster> request and set I<NumCacheNodes> equal to the
number of cache nodes currently in the cache cluster.










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










=head2 SecurityGroupIds => ArrayRef[Str]

  

Specifies the VPC Security Groups associated with the cache cluster.

This parameter can be used only with clusters that are created in an
Amazon Virtual Private Cloud (VPC).










=head2 SnapshotRetentionLimit => Int

  

The number of days for which ElastiCache will retain automatic cache
cluster snapshots before deleting them. For example, if you set
I<SnapshotRetentionLimit> to 5, then a snapshot that was taken today
will be retained for 5 days before being deleted.

B<Important>

If the value of SnapshotRetentionLimit is set to zero (0), backups are
turned off.










=head2 SnapshotWindow => Str

  

The daily time range (in UTC) during which ElastiCache will begin
taking a daily snapshot of your cache cluster.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyCacheCluster in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

