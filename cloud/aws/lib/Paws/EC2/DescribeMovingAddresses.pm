
package Paws::EC2::DescribeMovingAddresses {
  use Moose;
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'filter' );
  has MaxResults => (is => 'ro', isa => 'Int', traits => ['NameInRequest'], request_name => 'maxResults' );
  has NextToken => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'nextToken' );
  has PublicIps => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'publicIp' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeMovingAddresses');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeMovingAddressesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeMovingAddresses - Arguments for method DescribeMovingAddresses on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeMovingAddresses on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeMovingAddresses.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeMovingAddresses.

As an example:

  $service_obj->DescribeMovingAddresses(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 Filters => ArrayRef[Paws::EC2::Filter]

  

One or more filters.

=over

=item *

C<moving-status> - The status of the Elastic IP address (C<MovingToVpc>
| C<RestoringToClassic>).

=back










=head2 MaxResults => Int

  

The maximum number of results to return for the request in a single
page. The remaining results of the initial request can be seen by
sending another request with the returned C<NextToken> value. This
value can be between 5 and 1000; if C<MaxResults> is given a value
outside of this range, an error is returned.

Default: If no value is provided, the default is 1000.










=head2 NextToken => Str

  

The token to use to retrieve the next page of results.










=head2 PublicIps => ArrayRef[Str]

  

One or more Elastic IP addresses.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeMovingAddresses in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

