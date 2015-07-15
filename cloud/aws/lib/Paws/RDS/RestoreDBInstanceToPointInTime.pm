
package Paws::RDS::RestoreDBInstanceToPointInTime {
  use Moose;
  has AutoMinorVersionUpgrade => (is => 'ro', isa => 'Bool');
  has AvailabilityZone => (is => 'ro', isa => 'Str');
  has DBInstanceClass => (is => 'ro', isa => 'Str');
  has DBName => (is => 'ro', isa => 'Str');
  has DBSubnetGroupName => (is => 'ro', isa => 'Str');
  has Engine => (is => 'ro', isa => 'Str');
  has Iops => (is => 'ro', isa => 'Int');
  has LicenseModel => (is => 'ro', isa => 'Str');
  has MultiAZ => (is => 'ro', isa => 'Bool');
  has OptionGroupName => (is => 'ro', isa => 'Str');
  has Port => (is => 'ro', isa => 'Int');
  has PubliclyAccessible => (is => 'ro', isa => 'Bool');
  has RestoreTime => (is => 'ro', isa => 'Str');
  has SourceDBInstanceIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has StorageType => (is => 'ro', isa => 'Str');
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Tag]');
  has TargetDBInstanceIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has TdeCredentialArn => (is => 'ro', isa => 'Str');
  has TdeCredentialPassword => (is => 'ro', isa => 'Str');
  has UseLatestRestorableTime => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RestoreDBInstanceToPointInTime');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::RestoreDBInstanceToPointInTimeResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'RestoreDBInstanceToPointInTimeResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::RestoreDBInstanceToPointInTime - Arguments for method RestoreDBInstanceToPointInTime on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method RestoreDBInstanceToPointInTime on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method RestoreDBInstanceToPointInTime.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RestoreDBInstanceToPointInTime.

As an example:

  $service_obj->RestoreDBInstanceToPointInTime(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AutoMinorVersionUpgrade => Bool

  

Indicates that minor version upgrades will be applied automatically to
the DB instance during the maintenance window.










=head2 AvailabilityZone => Str

  

The EC2 Availability Zone that the database instance will be created
in.

Default: A random, system-chosen Availability Zone.

Constraint: You cannot specify the AvailabilityZone parameter if the
MultiAZ parameter is set to true.

Example: C<us-east-1a>










=head2 DBInstanceClass => Str

  

The compute and memory capacity of the Amazon RDS DB instance.

Valid Values: C<db.t1.micro | db.m1.small | db.m1.medium | db.m1.large
| db.m1.xlarge | db.m2.2xlarge | db.m2.4xlarge | db.m3.medium |
db.m3.large | db.m3.xlarge | db.m3.2xlarge | db.r3.large | db.r3.xlarge
| db.r3.2xlarge | db.r3.4xlarge | db.r3.8xlarge | db.t2.micro |
db.t2.small | db.t2.medium>

Default: The same DBInstanceClass as the original DB instance.










=head2 DBName => Str

  

The database name for the restored DB instance.

This parameter is not used for the MySQL engine.










=head2 DBSubnetGroupName => Str

  

The DB subnet group name to use for the new instance.










=head2 Engine => Str

  

The database engine to use for the new instance.

Default: The same as source

Constraint: Must be compatible with the engine of the source

Valid Values: C<MySQL> | C<oracle-se1> | C<oracle-se> | C<oracle-ee> |
C<sqlserver-ee> | C<sqlserver-se> | C<sqlserver-ex> | C<sqlserver-web>
| C<postgres>










=head2 Iops => Int

  

The amount of Provisioned IOPS (input/output operations per second) to
be initially allocated for the DB instance.

Constraints: Must be an integer greater than 1000.

B<SQL Server>

Setting the IOPS value for the SQL Server database engine is not
supported.










=head2 LicenseModel => Str

  

License model information for the restored DB instance.

Default: Same as source.

Valid values: C<license-included> | C<bring-your-own-license> |
C<general-public-license>










=head2 MultiAZ => Bool

  

Specifies if the DB instance is a Multi-AZ deployment.

Constraint: You cannot specify the AvailabilityZone parameter if the
MultiAZ parameter is set to C<true>.










=head2 OptionGroupName => Str

  

The name of the option group to be used for the restored DB instance.

Permanent options, such as the TDE option for Oracle Advanced Security
TDE, cannot be removed from an option group, and that option group
cannot be removed from a DB instance once it is associated with a DB
instance










=head2 Port => Int

  

The port number on which the database accepts connections.

Constraints: Value must be C<1150-65535>

Default: The same port as the original DB instance.










=head2 PubliclyAccessible => Bool

  

Specifies the accessibility options for the DB instance. A value of
true specifies an Internet-facing instance with a publicly resolvable
DNS name, which resolves to a public IP address. A value of false
specifies an internal instance with a DNS name that resolves to a
private IP address.

Default: The default behavior varies depending on whether a VPC has
been requested or not. The following list shows the default behavior in
each case.

=over

=item * B<Default VPC:>true

=item * B<VPC:>false

=back

If no DB subnet group has been specified as part of the request and the
PubliclyAccessible value has not been set, the DB instance will be
publicly accessible. If a specific DB subnet group has been specified
as part of the request and the PubliclyAccessible value has not been
set, the DB instance will be private.










=head2 RestoreTime => Str

  

The date and time to restore from.

Valid Values: Value must be a UTC time

Constraints:

=over

=item * Must be before the latest restorable time for the DB instance

=item * Cannot be specified if UseLatestRestorableTime parameter is
true

=back

Example: C<2009-09-07T23:45:00Z>










=head2 B<REQUIRED> SourceDBInstanceIdentifier => Str

  

The identifier of the source DB instance from which to restore.

Constraints:

=over

=item * Must be the identifier of an existing database instance

=item * Must contain from 1 to 63 alphanumeric characters or hyphens

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back










=head2 StorageType => Str

  

Specifies the storage type to be associated with the DB instance.

Valid values: C<standard | gp2 | io1>

If you specify C<io1>, you must also include a value for the C<Iops>
parameter.

Default: C<io1> if the C<Iops> parameter is specified; otherwise
C<standard>










=head2 Tags => ArrayRef[Paws::RDS::Tag]

  

=head2 B<REQUIRED> TargetDBInstanceIdentifier => Str

  

The name of the new database instance to be created.

Constraints:

=over

=item * Must contain from 1 to 63 alphanumeric characters or hyphens

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back










=head2 TdeCredentialArn => Str

  

The ARN from the Key Store with which to associate the instance for TDE
encryption.










=head2 TdeCredentialPassword => Str

  

The password for the given ARN from the Key Store in order to access
the device.










=head2 UseLatestRestorableTime => Bool

  

Specifies whether (C<true>) or not (C<false>) the DB instance is
restored from the latest backup time.

Default: C<false>

Constraints: Cannot be specified if RestoreTime parameter is provided.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RestoreDBInstanceToPointInTime in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

