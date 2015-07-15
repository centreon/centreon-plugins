
package Paws::RedShift::DescribeHsmClientCertificates {
  use Moose;
  has HsmClientCertificateIdentifier => (is => 'ro', isa => 'Str');
  has Marker => (is => 'ro', isa => 'Str');
  has MaxRecords => (is => 'ro', isa => 'Int');
  has TagKeys => (is => 'ro', isa => 'ArrayRef[Str]');
  has TagValues => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeHsmClientCertificates');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::RedShift::HsmClientCertificateMessage');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeHsmClientCertificatesResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::RedShift::DescribeHsmClientCertificates - Arguments for method DescribeHsmClientCertificates on Paws::RedShift

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeHsmClientCertificates on the 
Amazon Redshift service. Use the attributes of this class
as arguments to method DescribeHsmClientCertificates.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeHsmClientCertificates.

As an example:

  $service_obj->DescribeHsmClientCertificates(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 HsmClientCertificateIdentifier => Str

  

The identifier of a specific HSM client certificate for which you want
information. If no identifier is specified, information is returned for
all HSM client certificates owned by your AWS customer account.










=head2 Marker => Str

  

An optional parameter that specifies the starting point to return a set
of response records. When the results of a
DescribeHsmClientCertificates request exceed the value specified in
C<MaxRecords>, AWS returns a value in the C<Marker> field of the
response. You can retrieve the next set of response records by
providing the returned marker value in the C<Marker> parameter and
retrying the request.










=head2 MaxRecords => Int

  

The maximum number of response records to return in each call. If the
number of remaining response records exceeds the specified
C<MaxRecords> value, a value is returned in a C<marker> field of the
response. You can retrieve the next set of records by retrying the
command with the returned marker value.

Default: C<100>

Constraints: minimum 20, maximum 100.










=head2 TagKeys => ArrayRef[Str]

  

A tag key or keys for which you want to return all matching HSM client
certificates that are associated with the specified key or keys. For
example, suppose that you have HSM client certificates that are tagged
with keys called C<owner> and C<environment>. If you specify both of
these tag keys in the request, Amazon Redshift returns a response with
the HSM client certificates that have either or both of these tag keys
associated with them.










=head2 TagValues => ArrayRef[Str]

  

A tag value or values for which you want to return all matching HSM
client certificates that are associated with the specified tag value or
values. For example, suppose that you have HSM client certificates that
are tagged with values called C<admin> and C<test>. If you specify both
of these tag values in the request, Amazon Redshift returns a response
with the HSM client certificates that have either or both of these tag
values associated with them.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeHsmClientCertificates in L<Paws::RedShift>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

