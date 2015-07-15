
package Paws::EC2::DescribeAddresses {
  use Moose;
  has AllocationIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'AllocationId' );
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Filters => (is => 'ro', isa => 'ArrayRef[Paws::EC2::Filter]', traits => ['NameInRequest'], request_name => 'Filter' );
  has PublicIps => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'PublicIp' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeAddresses');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::DescribeAddressesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeAddresses - Arguments for method DescribeAddresses on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeAddresses on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method DescribeAddresses.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeAddresses.

As an example:

  $service_obj->DescribeAddresses(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AllocationIds => ArrayRef[Str]

  

[EC2-VPC] One or more allocation IDs.

Default: Describes all your Elastic IP addresses.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 Filters => ArrayRef[Paws::EC2::Filter]

  

One or more filters. Filter names and values are case-sensitive.

=over

=item *

C<allocation-id> - [EC2-VPC] The allocation ID for the address.

=item *

C<association-id> - [EC2-VPC] The association ID for the address.

=item *

C<domain> - Indicates whether the address is for use in EC2-Classic
(C<standard>) or in a VPC (C<vpc>).

=item *

C<instance-id> - The ID of the instance the address is associated with,
if any.

=item *

C<network-interface-id> - [EC2-VPC] The ID of the network interface
that the address is associated with, if any.

=item *

C<network-interface-owner-id> - The AWS account ID of the owner.

=item *

C<private-ip-address> - [EC2-VPC] The private IP address associated
with the Elastic IP address.

=item *

C<public-ip> - The Elastic IP address.

=back










=head2 PublicIps => ArrayRef[Str]

  

[EC2-Classic] One or more Elastic IP addresses.

Default: Describes all your Elastic IP addresses.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeAddresses in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

