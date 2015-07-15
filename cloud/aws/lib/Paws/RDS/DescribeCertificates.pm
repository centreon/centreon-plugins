
package Paws::RDS::DescribeCertificates {
  use Moose;
  has CertificateIdentifier => (is => 'ro', isa => 'Str');
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::RDS::Filter]');
  has Marker => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeCertificates');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RDS::CertificateMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeCertificatesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RDS::DescribeCertificates - Arguments for method DescribeCertificates on Paws::RDS

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeCertificates on the 
Amazon Relational Database Service service. Use the attributes of this class
as arguments to method DescribeCertificates.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeCertificates.

As an example:

  $service_obj->DescribeCertificates(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 CertificateIdentifier => Str

  

The user-supplied certificate identifier. If this parameter is
specified, information for only the identified certificate is returned.
This parameter isn't case-sensitive.

Constraints:

=over

=item * Must contain from 1 to 63 alphanumeric characters or hyphens

=item * First character must be a letter

=item * Cannot end with a hyphen or contain two consecutive hyphens

=back










=head2 Filters => ArrayRef[Paws::RDS::Filter]

  

This parameter is not currently supported.










=head2 Marker => Str

  

An optional pagination token provided by a previous
DescribeCertificates request. If this parameter is specified, the
response includes only records beyond the marker, up to the value
specified by C<MaxRecords>.










=head2 MaxRecords => Int

  

The maximum number of records to include in the response. If more
records exist than the specified C<MaxRecords> value, a pagination
token called a marker is included in the response so that the remaining
results can be retrieved.

Default: 100

Constraints: Minimum 20, maximum 100












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeCertificates in L<Paws::RDS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

