
package Paws::RDS::PromoteReadReplica {
  use Moose;
  has BackupRetentionPeriod => (is => 'ro', isa => 'Int');
  has DBInstanceIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has PreferredBackupWindow => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'PromoteReadReplica');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::PromoteReadReplicaResult');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'PromoteReadReplicaResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::PromoteReadReplica - Arguments for method PromoteReadReplica on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method PromoteReadReplica on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method PromoteReadReplica.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to PromoteReadReplica.

As an example:

  $service_obj->PromoteReadReplica(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 BackupRetentionPeriod => Int

  

The number of days to retain automated backups. Setting this parameter
to a positive number enables backups. Setting this parameter to 0
disables automated backups.

Default: 1

Constraints:

=over

=item * Must be a value from 0 to 8

=back










=head2 B<REQUIRED> DBInstanceIdentifier => Str

  

The DB instance identifier. This value is stored as a lowercase string.

Constraints:

=over

=item * Must be the identifier for an existing Read Replica DB instance

=item * Must contain from 1 to 63 alphanumeric characters or hyphens

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back

Example: mydbinstance










=head2 PreferredBackupWindow => Str

  

The daily time range during which automated backups are created if
automated backups are enabled, using the C<BackupRetentionPeriod>
parameter.

Default: A 30-minute window selected at random from an 8-hour block of
time per region. See the Amazon RDS User Guide for the time blocks for
each region from which the default backup windows are assigned.

Constraints: Must be in the format C<hh24:mi-hh24:mi>. Times should be
Universal Time Coordinated (UTC). Must not conflict with the preferred
maintenance window. Must be at least 30 minutes.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method PromoteReadReplica in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

