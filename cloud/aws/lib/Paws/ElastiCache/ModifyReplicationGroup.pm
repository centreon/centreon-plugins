
package Paws::ElastiCache::ModifyReplicationGroup {
  use Moose;
  has ApplyImmediately => (is => 'ro', isa => 'Bool');
  has AutomaticFailoverEnabled => (is => 'ro', isa => 'Bool');
  has AutoMinorVersionUpgrade => (is => 'ro', isa => 'Bool');
  has CacheParameterGroupName => (is => 'ro', isa => 'Str');
  has CacheSecurityGroupNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has EngineVersion => (is => 'ro', isa => 'Str');
  has NotificationTopicArn => (is => 'ro', isa => 'Str');
  has NotificationTopicStatus => (is => 'ro', isa => 'Str');
  has PreferredMaintenanceWindow => (is => 'ro', isa => 'Str');
  has PrimaryClusterId => (is => 'ro', isa => 'Str');
  has ReplicationGroupDescription => (is => 'ro', isa => 'Str');
  has ReplicationGroupId => (is => 'ro', isa => 'Str', required => 1);
  has SecurityGroupIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has SnapshotRetentionLimit => (is => 'ro', isa => 'Int');
  has SnapshottingClusterId => (is => 'ro', isa => 'Str');
  has SnapshotWindow => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyReplicationGroup');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElastiCache::ModifyReplicationGroupResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ModifyReplicationGroupResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElastiCache::ModifyReplicationGroup - Arguments for method ModifyReplicationGroup on Paws::ElastiCache

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyReplicationGroup on the 
Amazon ElastiCache service. Use the attributes of this class
as arguments to method ModifyReplicationGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyReplicationGroup.

As an example:

  $service_obj->ModifyReplicationGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ApplyImmediately => Bool

  

If C<true>, this parameter causes the modifications in this request and
any pending modifications to be applied, asynchronously and as soon as
possible, regardless of the I<PreferredMaintenanceWindow> setting for
the replication group.

If C<false>, then changes to the nodes in the replication group are
applied on the next maintenance reboot, or the next failure reboot,
whichever occurs first.

Valid values: C<true> | C<false>

Default: C<false>










=head2 AutomaticFailoverEnabled => Bool

  

Whether a read replica will be automatically promoted to read/write
primary if the existing primary encounters a failure.

Valid values: C<true> | C<false>

ElastiCache Multi-AZ replication groups are not supported on:

=over

=item * Redis versions earlier than 2.8.6.

=item * T1 and T2 cache node types.

=back










=head2 AutoMinorVersionUpgrade => Bool

  

This parameter is currently disabled.










=head2 CacheParameterGroupName => Str

  

The name of the cache parameter group to apply to all of the clusters
in this replication group. This change is asynchronously applied as
soon as possible for parameters when the I<ApplyImmediately> parameter
is specified as I<true> for this request.










=head2 CacheSecurityGroupNames => ArrayRef[Str]

  

A list of cache security group names to authorize for the clusters in
this replication group. This change is asynchronously applied as soon
as possible.

This parameter can be used only with replication group containing cache
clusters running outside of an Amazon Virtual Private Cloud (VPC).

Constraints: Must contain no more than 255 alphanumeric characters.
Must not be "Default".










=head2 EngineVersion => Str

  

The upgraded version of the cache engine to be run on the cache
clusters in the replication group.










=head2 NotificationTopicArn => Str

  

The Amazon Resource Name (ARN) of the Amazon SNS topic to which
notifications will be sent.

The Amazon SNS topic owner must be same as the replication group owner.










=head2 NotificationTopicStatus => Str

  

The status of the Amazon SNS notification topic for the replication
group. Notifications are sent only if the status is I<active>.

Valid values: C<active> | C<inactive>










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










=head2 PrimaryClusterId => Str

  

If this parameter is specified, ElastiCache will promote each of the
cache clusters in the specified replication group to the primary role.
The nodes of all other cache clusters in the replication group will be
read replicas.










=head2 ReplicationGroupDescription => Str

  

A description for the replication group. Maximum length is 255
characters.










=head2 B<REQUIRED> ReplicationGroupId => Str

  

The identifier of the replication group to modify.










=head2 SecurityGroupIds => ArrayRef[Str]

  

Specifies the VPC Security Groups associated with the cache clusters in
the replication group.

This parameter can be used only with replication group containing cache
clusters running in an Amazon Virtual Private Cloud (VPC).










=head2 SnapshotRetentionLimit => Int

  

The number of days for which ElastiCache will retain automatic node
group snapshots before deleting them. For example, if you set
I<SnapshotRetentionLimit> to 5, then a snapshot that was taken today
will be retained for 5 days before being deleted.

B<Important>

If the value of SnapshotRetentionLimit is set to zero (0), backups are
turned off.










=head2 SnapshottingClusterId => Str

  

The cache cluster ID that will be used as the daily snapshot source for
the replication group.










=head2 SnapshotWindow => Str

  

The daily time range (in UTC) during which ElastiCache will begin
taking a daily snapshot of the node group specified by
I<SnapshottingClusterId>.

Example: C<05:00-09:00>

If you do not specify this parameter, then ElastiCache will
automatically choose an appropriate time range.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyReplicationGroup in L<Paws::ElastiCache>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

