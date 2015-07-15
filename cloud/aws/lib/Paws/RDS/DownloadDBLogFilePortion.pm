
package Paws::RDS::DownloadDBLogFilePortion {
  use Moose;
  has DBInstanceIdentifier => (is => 'ro', isa => 'Str', required => 1);
  has LogFileName => (is => 'ro', isa => 'Str', required => 1);
  has Marker => (is => 'ro', isa => 'Str');
  has NumberOfLines => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DownloadDBLogFilePortion');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::DownloadDBLogFilePortionDetails');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DownloadDBLogFilePortionResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::DownloadDBLogFilePortion - Arguments for method DownloadDBLogFilePortion on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DownloadDBLogFilePortion on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method DownloadDBLogFilePortion.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DownloadDBLogFilePortion.

As an example:

  $service_obj->DownloadDBLogFilePortion(Att1 => $value1, Att2 => $value2, ...);

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










=head2 B<REQUIRED> LogFileName => Str

  

The name of the log file to be downloaded.










=head2 Marker => Str

  

The pagination token provided in the previous request or "0". If the
Marker parameter is specified the response includes only records beyond
the marker until the end of the file or up to NumberOfLines.










=head2 NumberOfLines => Int

  

The number of lines to download.

If the NumberOfLines parameter is specified, then the block of lines
returned can be from the beginning or the end of the log file,
depending on the value of the Marker parameter.

=over

=item *

If neither Marker or NumberOfLines are specified, the entire log file
is returned.

=item *

If NumberOfLines is specified and Marker is not specified, then the
most recent lines from the end of the log file are returned.

=item *

If Marker is specified as "0", then the specified number of lines from
the beginning of the log file are returned.

=item *

You can download the log file in blocks of lines by specifying the size
of the block using the NumberOfLines parameter, and by specifying a
value of "0" for the Marker parameter in your first request. Include
the Marker value returned in the response as the Marker value for the
next request, continuing until the AdditionalDataPending response
element returns false.

=back












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DownloadDBLogFilePortion in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

