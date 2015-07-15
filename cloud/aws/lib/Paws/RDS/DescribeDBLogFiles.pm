
package Paws::RDS::DescribeDBLogFiles {
  use Moose;
  has DBInstanceIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has FileLastWritten => (is => 'ro', isa => 'Int');
  has FilenameContains => (is => 'ro', isa => 'Str');
  has FileSize => (is => 'ro', isa => 'Int');
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Filter]');
  has Marker => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeDBLogFiles');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::DescribeDBLogFilesResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeDBLogFilesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::DescribeDBLogFiles - Arguments for method DescribeDBLogFiles on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeDBLogFiles on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method DescribeDBLogFiles.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeDBLogFiles.

As an example:

  $service_obj->DescribeDBLogFiles(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DBInstanceIdentifier => Str

  

The customer-assigned name of the DB instance that contains the log
files you want to list.

Constraints:

=over

=item * Must contain from 1 to 63 alphanumeric characters or hyphens

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back










=head2 FileLastWritten => Int

  

Filters the available log files for files written since the specified
date, in POSIX timestamp format.










=head2 FilenameContains => Str

  

Filters the available log files for log file names that contain the
specified string.










=head2 FileSize => Int

  

Filters the available log files for files larger than the specified
size.










=head2 Filters => ArrayRef[Paws::RDS::Filter]

  

This parameter is not currently supported.










=head2 Marker => Str

  

The pagination token provided in the previous request. If this
parameter is specified the response includes only records beyond the
marker, up to MaxRecords.










=head2 MaxRecords => Int

  

The maximum number of records to include in the response. If more
records exist than the specified MaxRecords value, a pagination token
called a marker is included in the response so that the remaining
results can be retrieved.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeDBLogFiles in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

