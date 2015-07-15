
package Paws::RDS::CreateDBInstanceReadReplica {
  use Moose;
  has AutoMinorVersionUpgrade => (is => 'ro', isa => 'Bool');
  has AvailabilityZone => (is => 'ro', isa => 'Str');
  has DBInstanceClass => (is => 'ro', isa => 'Str');
  has DBInstanceIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has DBSubnetGroupName => (is => 'ro', isa => 'Str');
  has Iops => (is => 'ro', isa => 'Int');
  has OptionGroupName => (is => 'ro', isa => 'Str');
  has Port => (is => 'ro', isa => 'Int');
  has PubliclyAccessible => (is => 'ro', isa => 'Bool');
  has SourceDBInstanceIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has StorageType => (is => 'ro', isa => 'Str');
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Tag]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateDBInstanceReadReplica');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::CreateDBInstanceReadReplicaResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreateDBInstanceReadReplicaResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::CreateDBInstanceReadReplica - Arguments for method CreateDBInstanceReadReplica on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateDBInstanceReadReplica on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method CreateDBInstanceReadReplica.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateDBInstanceReadReplica.

As an example:

  $service_obj->CreateDBInstanceReadReplica(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AutoMinorVersionUpgrade => Bool

  

Indicates that minor engine upgrades will be applied automatically to
the Read Replica during the maintenance window.

Default: Inherits from the source DB instance










=head2 AvailabilityZone => Str

  

The Amazon EC2 Availability Zone that the Read Replica will be created
in.

Default: A random, system-chosen Availability Zone in the endpoint's
region.

Example: C<us-east-1d>










=head2 DBInstanceClass => Str

  

The compute and memory capacity of the Read Replica.

Valid Values: C<db.m1.small | db.m1.medium | db.m1.large | db.m1.xlarge
| db.m2.xlarge |db.m2.2xlarge | db.m2.4xlarge | db.m3.medium |
db.m3.large | db.m3.xlarge | db.m3.2xlarge | db.r3.large | db.r3.xlarge
| db.r3.2xlarge | db.r3.4xlarge | db.r3.8xlarge | db.t2.micro |
db.t2.small | db.t2.medium>

Default: Inherits from the source DB instance.










=head2 B<REQUIRED> DBInstanceIdentifier => Str

  

The DB instance identifier of the Read Replica. This is the unique key
that identifies a DB instance. This parameter is stored as a lowercase
string.










=head2 DBSubnetGroupName => Str

  

Specifies a DB subnet group for the DB instance. The new DB instance
will be created in the VPC associated with the DB subnet group. If no
DB subnet group is specified, then the new DB instance is not created
in a VPC.

Constraints:

=over

=item * Can only be specified if the source DB instance identifier
specifies a DB instance in another region.

=item * The specified DB subnet group must be in the same region in
which the operation is running.

=item * All Read Replicas in one region that are created from the same
source DB instance must either:

=over

=item * Specify DB subnet groups from the same VPC. All these Read
Replicas will be created in the same VPC.

=item * Not specify a DB subnet group. All these Read Replicas will be
created outside of any VPC.

=back

=back










=head2 Iops => Int

  

The amount of Provisioned IOPS (input/output operations per second) to
be initially allocated for the DB instance.










=head2 OptionGroupName => Str

  

The option group the DB instance will be associated with. If omitted,
the default option group for the engine specified will be used.










=head2 Port => Int

  

The port number that the DB instance uses for connections.

Default: Inherits from the source DB instance

Valid Values: C<1150-65535>










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










=head2 B<REQUIRED> SourceDBInstanceIdentifier => Str

  

The identifier of the DB instance that will act as the source for the
Read Replica. Each DB instance can have up to five Read Replicas.

Constraints:

=over

=item * Must be the identifier of an existing DB instance.

=item * Can specify a DB instance that is a MySQL Read Replica only if
the source is running MySQL 5.6.

=item * Can specify a DB instance that is a PostgreSQL Read Replica
only if the source is running PostgreSQL 9.3.5.

=item * The specified DB instance must have automatic backups enabled,
its backup retention period must be greater than 0.

=item * If the source DB instance is in the same region as the Read
Replica, specify a valid DB instance identifier.

=item * If the source DB instance is in a different region than the
Read Replica, specify a valid DB instance ARN. For more information, go
to Constructing a Amazon RDS Amazon Resource Name (ARN).

=back










=head2 StorageType => Str

  

Specifies the storage type to be associated with the Read Replica.

Valid values: C<standard | gp2 | io1>

If you specify C<io1>, you must also include a value for the C<Iops>
parameter.

Default: C<io1> if the C<Iops> parameter is specified; otherwise
C<standard>










=head2 Tags => ArrayRef[Paws::RDS::Tag]

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateDBInstanceReadReplica in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

