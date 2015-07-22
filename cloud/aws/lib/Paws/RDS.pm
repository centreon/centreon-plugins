package Paws::RDS {
  use Moose;
  sub service { 'rds' }
  sub version { '2014-10-31' }
  sub flattened_arrays { 0 }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::QueryCaller', 'Paws::Net::XMLResponse';

  has '+region_rules' => (default => sub {
    my $regioninfo;
      $regioninfo = [
    {
      constraints => [
        [
          'region',
          'equals',
          'us-east-1'
        ]
      ],
      uri => 'https://rds.amazonaws.com'
    }
  ];

    return $regioninfo;
  });

  
  sub AddSourceIdentifierToSubscription {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::AddSourceIdentifierToSubscription', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AddTagsToResource {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::AddTagsToResource', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ApplyPendingMaintenanceAction {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::ApplyPendingMaintenanceAction', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub AuthorizeDBSecurityGroupIngress {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::AuthorizeDBSecurityGroupIngress', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CopyDBParameterGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::CopyDBParameterGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CopyDBSnapshot {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::CopyDBSnapshot', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CopyOptionGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::CopyOptionGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateDBInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::CreateDBInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateDBInstanceReadReplica {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::CreateDBInstanceReadReplica', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateDBParameterGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::CreateDBParameterGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateDBSecurityGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::CreateDBSecurityGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateDBSnapshot {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::CreateDBSnapshot', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateDBSubnetGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::CreateDBSubnetGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateEventSubscription {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::CreateEventSubscription', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateOptionGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::CreateOptionGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteDBInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DeleteDBInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteDBParameterGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DeleteDBParameterGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteDBSecurityGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DeleteDBSecurityGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteDBSnapshot {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DeleteDBSnapshot', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteDBSubnetGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DeleteDBSubnetGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteEventSubscription {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DeleteEventSubscription', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteOptionGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DeleteOptionGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeAccountAttributes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeAccountAttributes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeCertificates {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeCertificates', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeDBEngineVersions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeDBEngineVersions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeDBInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeDBInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeDBLogFiles {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeDBLogFiles', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeDBParameterGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeDBParameterGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeDBParameters {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeDBParameters', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeDBSecurityGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeDBSecurityGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeDBSnapshots {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeDBSnapshots', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeDBSubnetGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeDBSubnetGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeEngineDefaultParameters {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeEngineDefaultParameters', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeEventCategories {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeEventCategories', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeEvents {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeEvents', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeEventSubscriptions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeEventSubscriptions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeOptionGroupOptions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeOptionGroupOptions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeOptionGroups {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeOptionGroups', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeOrderableDBInstanceOptions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeOrderableDBInstanceOptions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribePendingMaintenanceActions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribePendingMaintenanceActions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeReservedDBInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeReservedDBInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeReservedDBInstancesOfferings {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DescribeReservedDBInstancesOfferings', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DownloadDBLogFilePortion {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::DownloadDBLogFilePortion', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListTagsForResource {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::ListTagsForResource', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyDBInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::ModifyDBInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyDBParameterGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::ModifyDBParameterGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyDBSubnetGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::ModifyDBSubnetGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyEventSubscription {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::ModifyEventSubscription', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ModifyOptionGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::ModifyOptionGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PromoteReadReplica {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::PromoteReadReplica', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PurchaseReservedDBInstancesOffering {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::PurchaseReservedDBInstancesOffering', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RebootDBInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::RebootDBInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RemoveSourceIdentifierFromSubscription {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::RemoveSourceIdentifierFromSubscription', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RemoveTagsFromResource {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::RemoveTagsFromResource', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ResetDBParameterGroup {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::ResetDBParameterGroup', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RestoreDBInstanceFromDBSnapshot {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::RestoreDBInstanceFromDBSnapshot', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RestoreDBInstanceToPointInTime {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::RestoreDBInstanceToPointInTime', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RevokeDBSecurityGroupIngress {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::RDS::RevokeDBSecurityGroupIngress', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS - Perl Interface to AWS Amazon Relational Database Service

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('RDS')->new;
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



Amazon Relational Database Service

Amazon Relational Database Service (Amazon RDS) is a web service that
makes it easier to set up, operate, and scale a relational database in
the cloud. It provides cost-efficient, resizable capacity for an
industry-standard relational database and manages common database
administration tasks, freeing up developers to focus on what makes
their applications and businesses unique.

Amazon RDS gives you access to the capabilities of a MySQL, PostgreSQL,
Microsoft SQL Server, Oracle, or Aurora database server. This means the
code, applications, and tools you already use today with your existing
databases work with Amazon RDS without modification. Amazon RDS
automatically backs up your database and maintains the database
software that powers your DB instance. Amazon RDS is flexible: you can
scale your database instance's compute resources and storage capacity
to meet your application's demand. As with all Amazon Web Services,
there are no up-front investments, and you pay only for the resources
you use.

This is an interface reference for Amazon RDS. It contains
documentation for a programming or command line interface you can use
to manage Amazon RDS. Note that Amazon RDS is asynchronous, which means
that some interfaces may require techniques such as polling or callback
functions to determine when a command has been applied. In this
reference, the parameter descriptions indicate whether a command is
applied immediately, on the next instance reboot, or during the
maintenance window. For a summary of the Amazon RDS interfaces, go to
Available RDS Interfaces.










=head1 METHODS

=head2 AddSourceIdentifierToSubscription(SourceIdentifier => Str, SubscriptionName => Str)

Each argument is described in detail in: L<Paws::RDS::AddSourceIdentifierToSubscription>

Returns: a L<Paws::RDS::AddSourceIdentifierToSubscriptionResult> instance

  

Adds a source identifier to an existing RDS event notification
subscription.











=head2 AddTagsToResource(ResourceName => Str, Tags => ArrayRef[Paws::RDS::Tag])

Each argument is described in detail in: L<Paws::RDS::AddTagsToResource>

Returns: nothing

  

Adds metadata tags to an Amazon RDS resource. These tags can also be
used with cost allocation reporting to track cost associated with
Amazon RDS resources, or used in Condition statement in IAM policy for
Amazon RDS.

For an overview on tagging Amazon RDS resources, see Tagging Amazon RDS
Resources.











=head2 ApplyPendingMaintenanceAction(ApplyAction => Str, OptInType => Str, ResourceIdentifier => Str)

Each argument is described in detail in: L<Paws::RDS::ApplyPendingMaintenanceAction>

Returns: a L<Paws::RDS::ApplyPendingMaintenanceActionResult> instance

  

Applies a pending maintenance action to a resource (for example, a DB
instance).











=head2 AuthorizeDBSecurityGroupIngress(DBSecurityGroupName => Str, [CIDRIP => Str, EC2SecurityGroupId => Str, EC2SecurityGroupName => Str, EC2SecurityGroupOwnerId => Str])

Each argument is described in detail in: L<Paws::RDS::AuthorizeDBSecurityGroupIngress>

Returns: a L<Paws::RDS::AuthorizeDBSecurityGroupIngressResult> instance

  

Enables ingress to a DBSecurityGroup using one of two forms of
authorization. First, EC2 or VPC security groups can be added to the
DBSecurityGroup if the application using the database is running on EC2
or VPC instances. Second, IP ranges are available if the application
accessing your database is running on the Internet. Required parameters
for this API are one of CIDR range, EC2SecurityGroupId for VPC, or
(EC2SecurityGroupOwnerId and either EC2SecurityGroupName or
EC2SecurityGroupId for non-VPC).

You cannot authorize ingress from an EC2 security group in one Region
to an Amazon RDS DB instance in another. You cannot authorize ingress
from a VPC security group in one VPC to an Amazon RDS DB instance in
another.

For an overview of CIDR ranges, go to the Wikipedia Tutorial.











=head2 CopyDBParameterGroup(SourceDBParameterGroupIdentifier => Str, TargetDBParameterGroupDescription => Str, TargetDBParameterGroupIdentifier => Str, [Tags => ArrayRef[Paws::RDS::Tag]])

Each argument is described in detail in: L<Paws::RDS::CopyDBParameterGroup>

Returns: a L<Paws::RDS::CopyDBParameterGroupResult> instance

  

Copies the specified DB parameter group.











=head2 CopyDBSnapshot(SourceDBSnapshotIdentifier => Str, TargetDBSnapshotIdentifier => Str, [Tags => ArrayRef[Paws::RDS::Tag]])

Each argument is described in detail in: L<Paws::RDS::CopyDBSnapshot>

Returns: a L<Paws::RDS::CopyDBSnapshotResult> instance

  

Copies the specified DBSnapshot. The source DBSnapshot must be in the
"available" state.











=head2 CopyOptionGroup(SourceOptionGroupIdentifier => Str, TargetOptionGroupDescription => Str, TargetOptionGroupIdentifier => Str, [Tags => ArrayRef[Paws::RDS::Tag]])

Each argument is described in detail in: L<Paws::RDS::CopyOptionGroup>

Returns: a L<Paws::RDS::CopyOptionGroupResult> instance

  

Copies the specified option group.











=head2 CreateDBInstance(AllocatedStorage => Int, DBInstanceClass => Str, DBInstanceIdentifier => Str, Engine => Str, MasterUsername => Str, MasterUserPassword => Str, [AutoMinorVersionUpgrade => Bool, AvailabilityZone => Str, BackupRetentionPeriod => Int, CharacterSetName => Str, DBName => Str, DBParameterGroupName => Str, DBSecurityGroups => ArrayRef[Str], DBSubnetGroupName => Str, EngineVersion => Str, Iops => Int, KmsKeyId => Str, LicenseModel => Str, MultiAZ => Bool, OptionGroupName => Str, Port => Int, PreferredBackupWindow => Str, PreferredMaintenanceWindow => Str, PubliclyAccessible => Bool, StorageEncrypted => Bool, StorageType => Str, Tags => ArrayRef[Paws::RDS::Tag], TdeCredentialArn => Str, TdeCredentialPassword => Str, VpcSecurityGroupIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::RDS::CreateDBInstance>

Returns: a L<Paws::RDS::CreateDBInstanceResult> instance

  

Creates a new DB instance.











=head2 CreateDBInstanceReadReplica(DBInstanceIdentifier => Str, SourceDBInstanceIdentifier => Str, [AutoMinorVersionUpgrade => Bool, AvailabilityZone => Str, DBInstanceClass => Str, DBSubnetGroupName => Str, Iops => Int, OptionGroupName => Str, Port => Int, PubliclyAccessible => Bool, StorageType => Str, Tags => ArrayRef[Paws::RDS::Tag]])

Each argument is described in detail in: L<Paws::RDS::CreateDBInstanceReadReplica>

Returns: a L<Paws::RDS::CreateDBInstanceReadReplicaResult> instance

  

Creates a DB instance that acts as a Read Replica of a source DB
instance.

All Read Replica DB instances are created as Single-AZ deployments with
backups disabled. All other DB instance attributes (including DB
security groups and DB parameter groups) are inherited from the source
DB instance, except as specified below.

The source DB instance must have backup retention enabled.











=head2 CreateDBParameterGroup(DBParameterGroupFamily => Str, DBParameterGroupName => Str, Description => Str, [Tags => ArrayRef[Paws::RDS::Tag]])

Each argument is described in detail in: L<Paws::RDS::CreateDBParameterGroup>

Returns: a L<Paws::RDS::CreateDBParameterGroupResult> instance

  

Creates a new DB parameter group.

A DB parameter group is initially created with the default parameters
for the database engine used by the DB instance. To provide custom
values for any of the parameters, you must modify the group after
creating it using I<ModifyDBParameterGroup>. Once you've created a DB
parameter group, you need to associate it with your DB instance using
I<ModifyDBInstance>. When you associate a new DB parameter group with a
running DB instance, you need to reboot the DB instance without
failover for the new DB parameter group and associated settings to take
effect.

After you create a DB parameter group, you should wait at least 5
minutes before creating your first DB instance that uses that DB
parameter group as the default parameter group. This allows Amazon RDS
to fully complete the create action before the parameter group is used
as the default for a new DB instance. This is especially important for
parameters that are critical when creating the default database for a
DB instance, such as the character set for the default database defined
by the C<character_set_database> parameter. You can use the I<Parameter
Groups> option of the Amazon RDS console or the I<DescribeDBParameters>
command to verify that your DB parameter group has been created or
modified.











=head2 CreateDBSecurityGroup(DBSecurityGroupDescription => Str, DBSecurityGroupName => Str, [Tags => ArrayRef[Paws::RDS::Tag]])

Each argument is described in detail in: L<Paws::RDS::CreateDBSecurityGroup>

Returns: a L<Paws::RDS::CreateDBSecurityGroupResult> instance

  

Creates a new DB security group. DB security groups control access to a
DB instance.











=head2 CreateDBSnapshot(DBInstanceIdentifier => Str, DBSnapshotIdentifier => Str, [Tags => ArrayRef[Paws::RDS::Tag]])

Each argument is described in detail in: L<Paws::RDS::CreateDBSnapshot>

Returns: a L<Paws::RDS::CreateDBSnapshotResult> instance

  

Creates a DBSnapshot. The source DBInstance must be in "available"
state.











=head2 CreateDBSubnetGroup(DBSubnetGroupDescription => Str, DBSubnetGroupName => Str, SubnetIds => ArrayRef[Str], [Tags => ArrayRef[Paws::RDS::Tag]])

Each argument is described in detail in: L<Paws::RDS::CreateDBSubnetGroup>

Returns: a L<Paws::RDS::CreateDBSubnetGroupResult> instance

  

Creates a new DB subnet group. DB subnet groups must contain at least
one subnet in at least two AZs in the region.











=head2 CreateEventSubscription(SnsTopicArn => Str, SubscriptionName => Str, [Enabled => Bool, EventCategories => ArrayRef[Str], SourceIds => ArrayRef[Str], SourceType => Str, Tags => ArrayRef[Paws::RDS::Tag]])

Each argument is described in detail in: L<Paws::RDS::CreateEventSubscription>

Returns: a L<Paws::RDS::CreateEventSubscriptionResult> instance

  

Creates an RDS event notification subscription. This action requires a
topic ARN (Amazon Resource Name) created by either the RDS console, the
SNS console, or the SNS API. To obtain an ARN with SNS, you must create
a topic in Amazon SNS and subscribe to the topic. The ARN is displayed
in the SNS console.

You can specify the type of source (SourceType) you want to be notified
of, provide a list of RDS sources (SourceIds) that triggers the events,
and provide a list of event categories (EventCategories) for events you
want to be notified of. For example, you can specify SourceType =
db-instance, SourceIds = mydbinstance1, mydbinstance2 and
EventCategories = Availability, Backup.

If you specify both the SourceType and SourceIds, such as SourceType =
db-instance and SourceIdentifier = myDBInstance1, you will be notified
of all the db-instance events for the specified source. If you specify
a SourceType but do not specify a SourceIdentifier, you will receive
notice of the events for that source type for all your RDS sources. If
you do not specify either the SourceType nor the SourceIdentifier, you
will be notified of events generated from all RDS sources belonging to
your customer account.











=head2 CreateOptionGroup(EngineName => Str, MajorEngineVersion => Str, OptionGroupDescription => Str, OptionGroupName => Str, [Tags => ArrayRef[Paws::RDS::Tag]])

Each argument is described in detail in: L<Paws::RDS::CreateOptionGroup>

Returns: a L<Paws::RDS::CreateOptionGroupResult> instance

  

Creates a new option group. You can create up to 20 option groups.











=head2 DeleteDBInstance(DBInstanceIdentifier => Str, [FinalDBSnapshotIdentifier => Str, SkipFinalSnapshot => Bool])

Each argument is described in detail in: L<Paws::RDS::DeleteDBInstance>

Returns: a L<Paws::RDS::DeleteDBInstanceResult> instance

  

The DeleteDBInstance action deletes a previously provisioned DB
instance. A successful response from the web service indicates the
request was received correctly. When you delete a DB instance, all
automated backups for that instance are deleted and cannot be
recovered. Manual DB snapshots of the DB instance to be deleted are not
deleted.

If a final DB snapshot is requested the status of the RDS instance will
be "deleting" until the DB snapshot is created. The API action
C<DescribeDBInstance> is used to monitor the status of this operation.
The action cannot be canceled or reverted once submitted.











=head2 DeleteDBParameterGroup(DBParameterGroupName => Str)

Each argument is described in detail in: L<Paws::RDS::DeleteDBParameterGroup>

Returns: nothing

  

Deletes a specified DBParameterGroup. The DBParameterGroup to be
deleted cannot be associated with any DB instances.











=head2 DeleteDBSecurityGroup(DBSecurityGroupName => Str)

Each argument is described in detail in: L<Paws::RDS::DeleteDBSecurityGroup>

Returns: nothing

  

Deletes a DB security group.

The specified DB security group must not be associated with any DB
instances.











=head2 DeleteDBSnapshot(DBSnapshotIdentifier => Str)

Each argument is described in detail in: L<Paws::RDS::DeleteDBSnapshot>

Returns: a L<Paws::RDS::DeleteDBSnapshotResult> instance

  

Deletes a DBSnapshot. If the snapshot is being copied, the copy
operation is terminated.

The DBSnapshot must be in the C<available> state to be deleted.











=head2 DeleteDBSubnetGroup(DBSubnetGroupName => Str)

Each argument is described in detail in: L<Paws::RDS::DeleteDBSubnetGroup>

Returns: nothing

  

Deletes a DB subnet group.

The specified database subnet group must not be associated with any DB
instances.











=head2 DeleteEventSubscription(SubscriptionName => Str)

Each argument is described in detail in: L<Paws::RDS::DeleteEventSubscription>

Returns: a L<Paws::RDS::DeleteEventSubscriptionResult> instance

  

Deletes an RDS event notification subscription.











=head2 DeleteOptionGroup(OptionGroupName => Str)

Each argument is described in detail in: L<Paws::RDS::DeleteOptionGroup>

Returns: nothing

  

Deletes an existing option group.











=head2 DescribeAccountAttributes( => )

Each argument is described in detail in: L<Paws::RDS::DescribeAccountAttributes>

Returns: a L<Paws::RDS::AccountAttributesMessage> instance

  

Lists all of the attributes for a customer account. The attributes
include Amazon RDS quotas for the account, such as the number of DB
instances allowed. The description for a quota includes the quota name,
current usage toward that quota, and the quota's maximum value.

This command does not take any parameters.











=head2 DescribeCertificates([CertificateIdentifier => Str, Filters => ArrayRef[Paws::RDS::Filter], Marker => Str, MaxRecords => Int])

Each argument is described in detail in: L<Paws::RDS::DescribeCertificates>

Returns: a L<Paws::RDS::CertificateMessage> instance

  

Lists the set of CA certificates provided by Amazon RDS for this AWS
account.











=head2 DescribeDBEngineVersions([DBParameterGroupFamily => Str, DefaultOnly => Bool, Engine => Str, EngineVersion => Str, Filters => ArrayRef[Paws::RDS::Filter], ListSupportedCharacterSets => Bool, Marker => Str, MaxRecords => Int])

Each argument is described in detail in: L<Paws::RDS::DescribeDBEngineVersions>

Returns: a L<Paws::RDS::DBEngineVersionMessage> instance

  

Returns a list of the available DB engines.











=head2 DescribeDBInstances([DBInstanceIdentifier => Str, Filters => ArrayRef[Paws::RDS::Filter], Marker => Str, MaxRecords => Int])

Each argument is described in detail in: L<Paws::RDS::DescribeDBInstances>

Returns: a L<Paws::RDS::DBInstanceMessage> instance

  

Returns information about provisioned RDS instances. This API supports
pagination.











=head2 DescribeDBLogFiles(DBInstanceIdentifier => Str, [FileLastWritten => Int, FilenameContains => Str, FileSize => Int, Filters => ArrayRef[Paws::RDS::Filter], Marker => Str, MaxRecords => Int])

Each argument is described in detail in: L<Paws::RDS::DescribeDBLogFiles>

Returns: a L<Paws::RDS::DescribeDBLogFilesResponse> instance

  

Returns a list of DB log files for the DB instance.











=head2 DescribeDBParameterGroups([DBParameterGroupName => Str, Filters => ArrayRef[Paws::RDS::Filter], Marker => Str, MaxRecords => Int])

Each argument is described in detail in: L<Paws::RDS::DescribeDBParameterGroups>

Returns: a L<Paws::RDS::DBParameterGroupsMessage> instance

  

Returns a list of C<DBParameterGroup> descriptions. If a
C<DBParameterGroupName> is specified, the list will contain only the
description of the specified DB parameter group.











=head2 DescribeDBParameters(DBParameterGroupName => Str, [Filters => ArrayRef[Paws::RDS::Filter], Marker => Str, MaxRecords => Int, Source => Str])

Each argument is described in detail in: L<Paws::RDS::DescribeDBParameters>

Returns: a L<Paws::RDS::DBParameterGroupDetails> instance

  

Returns the detailed parameter list for a particular DB parameter
group.











=head2 DescribeDBSecurityGroups([DBSecurityGroupName => Str, Filters => ArrayRef[Paws::RDS::Filter], Marker => Str, MaxRecords => Int])

Each argument is described in detail in: L<Paws::RDS::DescribeDBSecurityGroups>

Returns: a L<Paws::RDS::DBSecurityGroupMessage> instance

  

Returns a list of C<DBSecurityGroup> descriptions. If a
C<DBSecurityGroupName> is specified, the list will contain only the
descriptions of the specified DB security group.











=head2 DescribeDBSnapshots([DBInstanceIdentifier => Str, DBSnapshotIdentifier => Str, Filters => ArrayRef[Paws::RDS::Filter], Marker => Str, MaxRecords => Int, SnapshotType => Str])

Each argument is described in detail in: L<Paws::RDS::DescribeDBSnapshots>

Returns: a L<Paws::RDS::DBSnapshotMessage> instance

  

Returns information about DB snapshots. This API supports pagination.











=head2 DescribeDBSubnetGroups([DBSubnetGroupName => Str, Filters => ArrayRef[Paws::RDS::Filter], Marker => Str, MaxRecords => Int])

Each argument is described in detail in: L<Paws::RDS::DescribeDBSubnetGroups>

Returns: a L<Paws::RDS::DBSubnetGroupMessage> instance

  

Returns a list of DBSubnetGroup descriptions. If a DBSubnetGroupName is
specified, the list will contain only the descriptions of the specified
DBSubnetGroup.

For an overview of CIDR ranges, go to the Wikipedia Tutorial.











=head2 DescribeEngineDefaultParameters(DBParameterGroupFamily => Str, [Filters => ArrayRef[Paws::RDS::Filter], Marker => Str, MaxRecords => Int])

Each argument is described in detail in: L<Paws::RDS::DescribeEngineDefaultParameters>

Returns: a L<Paws::RDS::DescribeEngineDefaultParametersResult> instance

  

Returns the default engine and system parameter information for the
specified database engine.











=head2 DescribeEventCategories([Filters => ArrayRef[Paws::RDS::Filter], SourceType => Str])

Each argument is described in detail in: L<Paws::RDS::DescribeEventCategories>

Returns: a L<Paws::RDS::EventCategoriesMessage> instance

  

Displays a list of categories for all event source types, or, if
specified, for a specified source type. You can see a list of the event
categories and source types in the Events topic in the Amazon RDS User
Guide.











=head2 DescribeEvents([Duration => Int, EndTime => Str, EventCategories => ArrayRef[Str], Filters => ArrayRef[Paws::RDS::Filter], Marker => Str, MaxRecords => Int, SourceIdentifier => Str, SourceType => Str, StartTime => Str])

Each argument is described in detail in: L<Paws::RDS::DescribeEvents>

Returns: a L<Paws::RDS::EventsMessage> instance

  

Returns events related to DB instances, DB security groups, DB
snapshots, and DB parameter groups for the past 14 days. Events
specific to a particular DB instance, DB security group, database
snapshot, or DB parameter group can be obtained by providing the name
as a parameter. By default, the past hour of events are returned.











=head2 DescribeEventSubscriptions([Filters => ArrayRef[Paws::RDS::Filter], Marker => Str, MaxRecords => Int, SubscriptionName => Str])

Each argument is described in detail in: L<Paws::RDS::DescribeEventSubscriptions>

Returns: a L<Paws::RDS::EventSubscriptionsMessage> instance

  

Lists all the subscription descriptions for a customer account. The
description for a subscription includes SubscriptionName, SNSTopicARN,
CustomerID, SourceType, SourceID, CreationTime, and Status.

If you specify a SubscriptionName, lists the description for that
subscription.











=head2 DescribeOptionGroupOptions(EngineName => Str, [Filters => ArrayRef[Paws::RDS::Filter], MajorEngineVersion => Str, Marker => Str, MaxRecords => Int])

Each argument is described in detail in: L<Paws::RDS::DescribeOptionGroupOptions>

Returns: a L<Paws::RDS::OptionGroupOptionsMessage> instance

  

Describes all available options.











=head2 DescribeOptionGroups([EngineName => Str, Filters => ArrayRef[Paws::RDS::Filter], MajorEngineVersion => Str, Marker => Str, MaxRecords => Int, OptionGroupName => Str])

Each argument is described in detail in: L<Paws::RDS::DescribeOptionGroups>

Returns: a L<Paws::RDS::OptionGroups> instance

  

Describes the available option groups.











=head2 DescribeOrderableDBInstanceOptions(Engine => Str, [DBInstanceClass => Str, EngineVersion => Str, Filters => ArrayRef[Paws::RDS::Filter], LicenseModel => Str, Marker => Str, MaxRecords => Int, Vpc => Bool])

Each argument is described in detail in: L<Paws::RDS::DescribeOrderableDBInstanceOptions>

Returns: a L<Paws::RDS::OrderableDBInstanceOptionsMessage> instance

  

Returns a list of orderable DB instance options for the specified
engine.











=head2 DescribePendingMaintenanceActions([Filters => ArrayRef[Paws::RDS::Filter], Marker => Str, MaxRecords => Int, ResourceIdentifier => Str])

Each argument is described in detail in: L<Paws::RDS::DescribePendingMaintenanceActions>

Returns: a L<Paws::RDS::PendingMaintenanceActionsMessage> instance

  

Returns a list of resources (for example, DB instances) that have at
least one pending maintenance action.











=head2 DescribeReservedDBInstances([DBInstanceClass => Str, Duration => Str, Filters => ArrayRef[Paws::RDS::Filter], Marker => Str, MaxRecords => Int, MultiAZ => Bool, OfferingType => Str, ProductDescription => Str, ReservedDBInstanceId => Str, ReservedDBInstancesOfferingId => Str])

Each argument is described in detail in: L<Paws::RDS::DescribeReservedDBInstances>

Returns: a L<Paws::RDS::ReservedDBInstanceMessage> instance

  

Returns information about reserved DB instances for this account, or
about a specified reserved DB instance.











=head2 DescribeReservedDBInstancesOfferings([DBInstanceClass => Str, Duration => Str, Filters => ArrayRef[Paws::RDS::Filter], Marker => Str, MaxRecords => Int, MultiAZ => Bool, OfferingType => Str, ProductDescription => Str, ReservedDBInstancesOfferingId => Str])

Each argument is described in detail in: L<Paws::RDS::DescribeReservedDBInstancesOfferings>

Returns: a L<Paws::RDS::ReservedDBInstancesOfferingMessage> instance

  

Lists available reserved DB instance offerings.











=head2 DownloadDBLogFilePortion(DBInstanceIdentifier => Str, LogFileName => Str, [Marker => Str, NumberOfLines => Int])

Each argument is described in detail in: L<Paws::RDS::DownloadDBLogFilePortion>

Returns: a L<Paws::RDS::DownloadDBLogFilePortionDetails> instance

  

Downloads all or a portion of the specified log file.











=head2 ListTagsForResource(ResourceName => Str, [Filters => ArrayRef[Paws::RDS::Filter]])

Each argument is described in detail in: L<Paws::RDS::ListTagsForResource>

Returns: a L<Paws::RDS::TagListMessage> instance

  

Lists all tags on an Amazon RDS resource.

For an overview on tagging an Amazon RDS resource, see Tagging Amazon
RDS Resources.











=head2 ModifyDBInstance(DBInstanceIdentifier => Str, [AllocatedStorage => Int, AllowMajorVersionUpgrade => Bool, ApplyImmediately => Bool, AutoMinorVersionUpgrade => Bool, BackupRetentionPeriod => Int, CACertificateIdentifier => Str, DBInstanceClass => Str, DBParameterGroupName => Str, DBSecurityGroups => ArrayRef[Str], EngineVersion => Str, Iops => Int, MasterUserPassword => Str, MultiAZ => Bool, NewDBInstanceIdentifier => Str, OptionGroupName => Str, PreferredBackupWindow => Str, PreferredMaintenanceWindow => Str, StorageType => Str, TdeCredentialArn => Str, TdeCredentialPassword => Str, VpcSecurityGroupIds => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::RDS::ModifyDBInstance>

Returns: a L<Paws::RDS::ModifyDBInstanceResult> instance

  

Modify settings for a DB instance. You can change one or more database
configuration parameters by specifying these parameters and the new
values in the request.











=head2 ModifyDBParameterGroup(DBParameterGroupName => Str, Parameters => ArrayRef[Paws::RDS::Parameter])

Each argument is described in detail in: L<Paws::RDS::ModifyDBParameterGroup>

Returns: a L<Paws::RDS::DBParameterGroupNameMessage> instance

  

Modifies the parameters of a DB parameter group. To modify more than
one parameter, submit a list of the following: C<ParameterName>,
C<ParameterValue>, and C<ApplyMethod>. A maximum of 20 parameters can
be modified in a single request.

Changes to dynamic parameters are applied immediately. Changes to
static parameters require a reboot without failover to the DB instance
associated with the parameter group before the change can take effect.

After you modify a DB parameter group, you should wait at least 5
minutes before creating your first DB instance that uses that DB
parameter group as the default parameter group. This allows Amazon RDS
to fully complete the modify action before the parameter group is used
as the default for a new DB instance. This is especially important for
parameters that are critical when creating the default database for a
DB instance, such as the character set for the default database defined
by the C<character_set_database> parameter. You can use the I<Parameter
Groups> option of the Amazon RDS console or the I<DescribeDBParameters>
command to verify that your DB parameter group has been created or
modified.











=head2 ModifyDBSubnetGroup(DBSubnetGroupName => Str, SubnetIds => ArrayRef[Str], [DBSubnetGroupDescription => Str])

Each argument is described in detail in: L<Paws::RDS::ModifyDBSubnetGroup>

Returns: a L<Paws::RDS::ModifyDBSubnetGroupResult> instance

  

Modifies an existing DB subnet group. DB subnet groups must contain at
least one subnet in at least two AZs in the region.











=head2 ModifyEventSubscription(SubscriptionName => Str, [Enabled => Bool, EventCategories => ArrayRef[Str], SnsTopicArn => Str, SourceType => Str])

Each argument is described in detail in: L<Paws::RDS::ModifyEventSubscription>

Returns: a L<Paws::RDS::ModifyEventSubscriptionResult> instance

  

Modifies an existing RDS event notification subscription. Note that you
cannot modify the source identifiers using this call; to change source
identifiers for a subscription, use the
AddSourceIdentifierToSubscription and
RemoveSourceIdentifierFromSubscription calls.

You can see a list of the event categories for a given SourceType in
the Events topic in the Amazon RDS User Guide or by using the
B<DescribeEventCategories> action.











=head2 ModifyOptionGroup(OptionGroupName => Str, [ApplyImmediately => Bool, OptionsToInclude => ArrayRef[Paws::RDS::OptionConfiguration], OptionsToRemove => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::RDS::ModifyOptionGroup>

Returns: a L<Paws::RDS::ModifyOptionGroupResult> instance

  

Modifies an existing option group.











=head2 PromoteReadReplica(DBInstanceIdentifier => Str, [BackupRetentionPeriod => Int, PreferredBackupWindow => Str])

Each argument is described in detail in: L<Paws::RDS::PromoteReadReplica>

Returns: a L<Paws::RDS::PromoteReadReplicaResult> instance

  

Promotes a Read Replica DB instance to a standalone DB instance.

We recommend that you enable automated backups on your Read Replica
before promoting the Read Replica. This ensures that no backup is taken
during the promotion process. Once the instance is promoted to a
primary instance, backups are taken based on your backup settings.











=head2 PurchaseReservedDBInstancesOffering(ReservedDBInstancesOfferingId => Str, [DBInstanceCount => Int, ReservedDBInstanceId => Str, Tags => ArrayRef[Paws::RDS::Tag]])

Each argument is described in detail in: L<Paws::RDS::PurchaseReservedDBInstancesOffering>

Returns: a L<Paws::RDS::PurchaseReservedDBInstancesOfferingResult> instance

  

Purchases a reserved DB instance offering.











=head2 RebootDBInstance(DBInstanceIdentifier => Str, [ForceFailover => Bool])

Each argument is described in detail in: L<Paws::RDS::RebootDBInstance>

Returns: a L<Paws::RDS::RebootDBInstanceResult> instance

  

Rebooting a DB instance restarts the database engine service. A reboot
also applies to the DB instance any modifications to the associated DB
parameter group that were pending. Rebooting a DB instance results in a
momentary outage of the instance, during which the DB instance status
is set to rebooting. If the RDS instance is configured for MultiAZ, it
is possible that the reboot will be conducted through a failover. An
Amazon RDS event is created when the reboot is completed.

If your DB instance is deployed in multiple Availability Zones, you can
force a failover from one AZ to the other during the reboot. You might
force a failover to test the availability of your DB instance
deployment or to restore operations to the original AZ after a failover
occurs.

The time required to reboot is a function of the specific database
engine's crash recovery process. To improve the reboot time, we
recommend that you reduce database activities as much as possible
during the reboot process to reduce rollback activity for in-transit
transactions.











=head2 RemoveSourceIdentifierFromSubscription(SourceIdentifier => Str, SubscriptionName => Str)

Each argument is described in detail in: L<Paws::RDS::RemoveSourceIdentifierFromSubscription>

Returns: a L<Paws::RDS::RemoveSourceIdentifierFromSubscriptionResult> instance

  

Removes a source identifier from an existing RDS event notification
subscription.











=head2 RemoveTagsFromResource(ResourceName => Str, TagKeys => ArrayRef[Str])

Each argument is described in detail in: L<Paws::RDS::RemoveTagsFromResource>

Returns: nothing

  

Removes metadata tags from an Amazon RDS resource.

For an overview on tagging an Amazon RDS resource, see Tagging Amazon
RDS Resources.











=head2 ResetDBParameterGroup(DBParameterGroupName => Str, [Parameters => ArrayRef[Paws::RDS::Parameter], ResetAllParameters => Bool])

Each argument is described in detail in: L<Paws::RDS::ResetDBParameterGroup>

Returns: a L<Paws::RDS::DBParameterGroupNameMessage> instance

  

Modifies the parameters of a DB parameter group to the engine/system
default value. To reset specific parameters submit a list of the
following: C<ParameterName> and C<ApplyMethod>. To reset the entire DB
parameter group, specify the C<DBParameterGroup> name and
C<ResetAllParameters> parameters. When resetting the entire group,
dynamic parameters are updated immediately and static parameters are
set to C<pending-reboot> to take effect on the next DB instance restart
or C<RebootDBInstance> request.











=head2 RestoreDBInstanceFromDBSnapshot(DBInstanceIdentifier => Str, DBSnapshotIdentifier => Str, [AutoMinorVersionUpgrade => Bool, AvailabilityZone => Str, DBInstanceClass => Str, DBName => Str, DBSubnetGroupName => Str, Engine => Str, Iops => Int, LicenseModel => Str, MultiAZ => Bool, OptionGroupName => Str, Port => Int, PubliclyAccessible => Bool, StorageType => Str, Tags => ArrayRef[Paws::RDS::Tag], TdeCredentialArn => Str, TdeCredentialPassword => Str])

Each argument is described in detail in: L<Paws::RDS::RestoreDBInstanceFromDBSnapshot>

Returns: a L<Paws::RDS::RestoreDBInstanceFromDBSnapshotResult> instance

  

Creates a new DB instance from a DB snapshot. The target database is
created from the source database restore point with the same
configuration as the original source database, except that the new RDS
instance is created with the default security group.

If your intent is to replace your original DB instance with the new,
restored DB instance, then rename your original DB instance before you
call the RestoreDBInstanceFromDBSnapshot action. RDS does not allow two
DB instances with the same name. Once you have renamed your original DB
instance with a different identifier, then you can pass the original
name of the DB instance as the DBInstanceIdentifier in the call to the
RestoreDBInstanceFromDBSnapshot action. The result is that you will
replace the original DB instance with the DB instance created from the
snapshot.











=head2 RestoreDBInstanceToPointInTime(SourceDBInstanceIdentifier => Str, TargetDBInstanceIdentifier => Str, [AutoMinorVersionUpgrade => Bool, AvailabilityZone => Str, DBInstanceClass => Str, DBName => Str, DBSubnetGroupName => Str, Engine => Str, Iops => Int, LicenseModel => Str, MultiAZ => Bool, OptionGroupName => Str, Port => Int, PubliclyAccessible => Bool, RestoreTime => Str, StorageType => Str, Tags => ArrayRef[Paws::RDS::Tag], TdeCredentialArn => Str, TdeCredentialPassword => Str, UseLatestRestorableTime => Bool])

Each argument is described in detail in: L<Paws::RDS::RestoreDBInstanceToPointInTime>

Returns: a L<Paws::RDS::RestoreDBInstanceToPointInTimeResult> instance

  

Restores a DB instance to an arbitrary point-in-time. Users can restore
to any point in time before the LatestRestorableTime for up to
BackupRetentionPeriod days. The target database is created from the
source database with the same configuration as the original database
except that the DB instance is created with the default DB security
group.











=head2 RevokeDBSecurityGroupIngress(DBSecurityGroupName => Str, [CIDRIP => Str, EC2SecurityGroupId => Str, EC2SecurityGroupName => Str, EC2SecurityGroupOwnerId => Str])

Each argument is described in detail in: L<Paws::RDS::RevokeDBSecurityGroupIngress>

Returns: a L<Paws::RDS::RevokeDBSecurityGroupIngressResult> instance

  

Revokes ingress from a DBSecurityGroup for previously authorized IP
ranges or EC2 or VPC Security Groups. Required parameters for this API
are one of CIDRIP, EC2SecurityGroupId for VPC, or
(EC2SecurityGroupOwnerId and either EC2SecurityGroupName or
EC2SecurityGroupId).











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

