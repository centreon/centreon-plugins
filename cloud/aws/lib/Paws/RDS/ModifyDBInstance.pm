
package Paws::RDS::ModifyDBInstance {
  use Moose;
  has AllocatedStorage => (is => 'ro', isa => 'Int');
  has AllowMajorVersionUpgrade => (is => 'ro', isa => 'Bool');
  has ApplyImmediately => (is => 'ro', isa => 'Bool');
  has AutoMinorVersionUpgrade => (is => 'ro', isa => 'Bool');
  has BackupRetentionPeriod => (is => 'ro', isa => 'Int');
  has CACertificateIdentifier => (is => 'ro', isa => 'Str');
  has DBInstanceClass => (is => 'ro', isa => 'Str');
  has DBInstanceIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has DBParameterGroupName => (is => 'ro', isa => 'Str');
  has DBSecurityGroups => (is => 'ro', isa => 'ArrayRef[Str]');
  has EngineVersion => (is => 'ro', isa => 'Str');
  has Iops => (is => 'ro', isa => 'Int');
  has MasterUserPassword => (is => 'ro', isa => 'Str');
  has MultiAZ => (is => 'ro', isa => 'Bool');
  has NewDBInstanceIdentifier => (is => 'ro', isa => 'Str');
  has OptionGroupName => (is => 'ro', isa => 'Str');
  has PreferredBackupWindow => (is => 'ro', isa => 'Str');
  has PreferredMaintenanceWindow => (is => 'ro', isa => 'Str');
  has StorageType => (is => 'ro', isa => 'Str');
  has TdeCredentialArn => (is => 'ro', isa => 'Str');
  has TdeCredentialPassword => (is => 'ro', isa => 'Str');
  has VpcSecurityGroupIds => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyDBInstance');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::ModifyDBInstanceResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ModifyDBInstanceResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::ModifyDBInstance - Arguments for method ModifyDBInstance on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyDBInstance on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method ModifyDBInstance.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyDBInstance.

As an example:

  $service_obj->ModifyDBInstance(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AllocatedStorage => Int

  

The new storage capacity of the RDS instance. Changing this setting
does not result in an outage and the change is applied during the next
maintenance window unless C<ApplyImmediately> is set to C<true> for
this request.

B<MySQL>

Default: Uses existing setting

Valid Values: 5-3072

Constraints: Value supplied must be at least 10% greater than the
current value. Values that are not at least 10% greater than the
existing value are rounded up so that they are 10% greater than the
current value.

Type: Integer

B<PostgreSQL>

Default: Uses existing setting

Valid Values: 5-3072

Constraints: Value supplied must be at least 10% greater than the
current value. Values that are not at least 10% greater than the
existing value are rounded up so that they are 10% greater than the
current value.

Type: Integer

B<Oracle>

Default: Uses existing setting

Valid Values: 10-3072

Constraints: Value supplied must be at least 10% greater than the
current value. Values that are not at least 10% greater than the
existing value are rounded up so that they are 10% greater than the
current value.

B<SQL Server>

Cannot be modified.

If you choose to migrate your DB instance from using standard storage
to using Provisioned IOPS, or from using Provisioned IOPS to using
standard storage, the process can take time. The duration of the
migration depends on several factors such as database load, storage
size, storage type (standard or Provisioned IOPS), amount of IOPS
provisioned (if any), and the number of prior scale storage operations.
Typical migration times are under 24 hours, but the process can take up
to several days in some cases. During the migration, the DB instance
will be available for use, but may experience performance degradation.
While the migration takes place, nightly backups for the instance will
be suspended. No other Amazon RDS operations can take place for the
instance, including modifying the instance, rebooting the instance,
deleting the instance, creating a Read Replica for the instance, and
creating a DB snapshot of the instance.










=head2 AllowMajorVersionUpgrade => Bool

  

Indicates that major version upgrades are allowed. Changing this
parameter does not result in an outage and the change is asynchronously
applied as soon as possible.

Constraints: This parameter must be set to true when specifying a value
for the EngineVersion parameter that is a different major version than
the DB instance's current version.










=head2 ApplyImmediately => Bool

  

Specifies whether the modifications in this request and any pending
modifications are asynchronously applied as soon as possible,
regardless of the C<PreferredMaintenanceWindow> setting for the DB
instance.

If this parameter is set to C<false>, changes to the DB instance are
applied during the next maintenance window. Some parameter changes can
cause an outage and will be applied on the next call to
RebootDBInstance, or the next failure reboot. Review the table of
parameters in Modifying a DB Instance and Using the Apply Immediately
Parameter to see the impact that setting C<ApplyImmediately> to C<true>
or C<false> has for each modified parameter and to determine when the
changes will be applied.

Default: C<false>










=head2 AutoMinorVersionUpgrade => Bool

  

Indicates that minor version upgrades will be applied automatically to
the DB instance during the maintenance window. Changing this parameter
does not result in an outage except in the following case and the
change is asynchronously applied as soon as possible. An outage will
result if this parameter is set to C<true> during the maintenance
window, and a newer minor version is available, and RDS has enabled
auto patching for that engine version.










=head2 BackupRetentionPeriod => Int

  

The number of days to retain automated backups. Setting this parameter
to a positive number enables backups. Setting this parameter to 0
disables automated backups.

Changing this parameter can result in an outage if you change from 0 to
a non-zero value or from a non-zero value to 0. These changes are
applied during the next maintenance window unless the
C<ApplyImmediately> parameter is set to C<true> for this request. If
you change the parameter from one non-zero value to another non-zero
value, the change is asynchronously applied as soon as possible.

Default: Uses existing setting

Constraints:

=over

=item * Must be a value from 0 to 35

=item * Can be specified for a MySQL Read Replica only if the source is
running MySQL 5.6

=item * Can be specified for a PostgreSQL Read Replica only if the
source is running PostgreSQL 9.3.5

=item * Cannot be set to 0 if the DB instance is a source to Read
Replicas

=back










=head2 CACertificateIdentifier => Str

  

Indicates the certificate which needs to be associated with the
instance.










=head2 DBInstanceClass => Str

  

The new compute and memory capacity of the DB instance. To determine
the instance classes that are available for a particular DB engine, use
the DescribeOrderableDBInstanceOptions action.

Passing a value for this setting causes an outage during the change and
is applied during the next maintenance window, unless
C<ApplyImmediately> is specified as C<true> for this request.

Default: Uses existing setting

Valid Values: C<db.t1.micro | db.m1.small | db.m1.medium | db.m1.large
| db.m1.xlarge | db.m2.xlarge | db.m2.2xlarge | db.m2.4xlarge |
db.m3.medium | db.m3.large | db.m3.xlarge | db.m3.2xlarge | db.r3.large
| db.r3.xlarge | db.r3.2xlarge | db.r3.4xlarge | db.r3.8xlarge |
db.t2.micro | db.t2.small | db.t2.medium>










=head2 B<REQUIRED> DBInstanceIdentifier => Str

  

The DB instance identifier. This value is stored as a lowercase string.

Constraints:

=over

=item * Must be the identifier for an existing DB instance

=item * Must contain from 1 to 63 alphanumeric characters or hyphens

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back










=head2 DBParameterGroupName => Str

  

The name of the DB parameter group to apply to the DB instance.
Changing this setting does not result in an outage. The parameter group
name itself is changed immediately, but the actual parameter changes
are not applied until you reboot the instance without failover. The db
instance will NOT be rebooted automatically and the parameter changes
will NOT be applied during the next maintenance window.

Default: Uses existing setting

Constraints: The DB parameter group must be in the same DB parameter
group family as this DB instance.










=head2 DBSecurityGroups => ArrayRef[Str]

  

A list of DB security groups to authorize on this DB instance. Changing
this setting does not result in an outage and the change is
asynchronously applied as soon as possible.

Constraints:

=over

=item * Must be 1 to 255 alphanumeric characters

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back










=head2 EngineVersion => Str

  

The version number of the database engine to upgrade to. Changing this
parameter results in an outage and the change is applied during the
next maintenance window unless the C<ApplyImmediately> parameter is set
to C<true> for this request.

For major version upgrades, if a non-default DB parameter group is
currently in use, a new DB parameter group in the DB parameter group
family for the new engine version must be specified. The new DB
parameter group can be the default for that DB parameter group family.

For a list of valid engine versions, see CreateDBInstance.










=head2 Iops => Int

  

The new Provisioned IOPS (I/O operations per second) value for the RDS
instance. Changing this setting does not result in an outage and the
change is applied during the next maintenance window unless the
C<ApplyImmediately> parameter is set to C<true> for this request.

Default: Uses existing setting

Constraints: Value supplied must be at least 10% greater than the
current value. Values that are not at least 10% greater than the
existing value are rounded up so that they are 10% greater than the
current value. If you are migrating from Provisioned IOPS to standard
storage, set this value to 0. The DB instance will require a reboot for
the change in storage type to take effect.

B<SQL Server>

Setting the IOPS value for the SQL Server database engine is not
supported.

Type: Integer

If you choose to migrate your DB instance from using standard storage
to using Provisioned IOPS, or from using Provisioned IOPS to using
standard storage, the process can take time. The duration of the
migration depends on several factors such as database load, storage
size, storage type (standard or Provisioned IOPS), amount of IOPS
provisioned (if any), and the number of prior scale storage operations.
Typical migration times are under 24 hours, but the process can take up
to several days in some cases. During the migration, the DB instance
will be available for use, but may experience performance degradation.
While the migration takes place, nightly backups for the instance will
be suspended. No other Amazon RDS operations can take place for the
instance, including modifying the instance, rebooting the instance,
deleting the instance, creating a Read Replica for the instance, and
creating a DB snapshot of the instance.










=head2 MasterUserPassword => Str

  

The new password for the DB instance master user. Can be any printable
ASCII character except "/", """, or "@".

Changing this parameter does not result in an outage and the change is
asynchronously applied as soon as possible. Between the time of the
request and the completion of the request, the C<MasterUserPassword>
element exists in the C<PendingModifiedValues> element of the operation
response.

Default: Uses existing setting

Constraints: Must be 8 to 41 alphanumeric characters (MySQL), 8 to 30
alphanumeric characters (Oracle), or 8 to 128 alphanumeric characters
(SQL Server).

Amazon RDS API actions never return the password, so this action
provides a way to regain access to a primary instance user if the
password is lost. This includes restoring privileges that may have been
accidentally revoked.










=head2 MultiAZ => Bool

  

Specifies if the DB instance is a Multi-AZ deployment. Changing this
parameter does not result in an outage and the change is applied during
the next maintenance window unless the C<ApplyImmediately> parameter is
set to C<true> for this request.

Constraints: Cannot be specified if the DB instance is a Read Replica.










=head2 NewDBInstanceIdentifier => Str

  

The new DB instance identifier for the DB instance when renaming a DB
instance. When you change the DB instance identifier, an instance
reboot will occur immediately if you set C<Apply Immediately> to true,
or will occur during the next maintenance window if C<Apply
Immediately> to false. This value is stored as a lowercase string.

Constraints:

=over

=item * Must contain from 1 to 63 alphanumeric characters or hyphens

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back










=head2 OptionGroupName => Str

  

Indicates that the DB instance should be associated with the specified
option group. Changing this parameter does not result in an outage
except in the following case and the change is applied during the next
maintenance window unless the C<ApplyImmediately> parameter is set to
C<true> for this request. If the parameter change results in an option
group that enables OEM, this change can cause a brief (sub-second)
period during which new connections are rejected but existing
connections are not interrupted.

Permanent options, such as the TDE option for Oracle Advanced Security
TDE, cannot be removed from an option group, and that option group
cannot be removed from a DB instance once it is associated with a DB
instance










=head2 PreferredBackupWindow => Str

  

The daily time range during which automated backups are created if
automated backups are enabled, as determined by the
C<BackupRetentionPeriod>. Changing this parameter does not result in an
outage and the change is asynchronously applied as soon as possible.

Constraints:

=over

=item * Must be in the format hh24:mi-hh24:mi

=item * Times should be Universal Time Coordinated (UTC)

=item * Must not conflict with the preferred maintenance window

=item * Must be at least 30 minutes

=back










=head2 PreferredMaintenanceWindow => Str

  

The weekly time range (in UTC) during which system maintenance can
occur, which may result in an outage. Changing this parameter does not
result in an outage, except in the following situation, and the change
is asynchronously applied as soon as possible. If there are pending
actions that cause a reboot, and the maintenance window is changed to
include the current time, then changing this parameter will cause a
reboot of the DB instance. If moving this window to the current time,
there must be at least 30 minutes between the current time and end of
the window to ensure pending changes are applied.

Default: Uses existing setting

Format: ddd:hh24:mi-ddd:hh24:mi

Valid Days: Mon | Tue | Wed | Thu | Fri | Sat | Sun

Constraints: Must be at least 30 minutes










=head2 StorageType => Str

  

Specifies the storage type to be associated with the DB instance.

Valid values: C<standard | gp2 | io1>

If you specify C<io1>, you must also include a value for the C<Iops>
parameter.

Default: C<io1> if the C<Iops> parameter is specified; otherwise
C<standard>










=head2 TdeCredentialArn => Str

  

The ARN from the Key Store with which to associate the instance for TDE
encryption.










=head2 TdeCredentialPassword => Str

  

The password for the given ARN from the Key Store in order to access
the device.










=head2 VpcSecurityGroupIds => ArrayRef[Str]

  

A list of EC2 VPC security groups to authorize on this DB instance.
This change is asynchronously applied as soon as possible.

Constraints:

=over

=item * Must be 1 to 255 alphanumeric characters

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyDBInstance in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

