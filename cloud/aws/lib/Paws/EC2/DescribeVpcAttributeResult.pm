
package Paws::EC2::DescribeVpcAttributeResult {
  use Moose;
  has EnableDnsHostnames => (is => 'ro', isa => 'Paws::EC2::AttributeBooleanValue', xmlname => 'enableDnsHostnames', traits => ['Unwrapped',]);
  has EnableDnsSupport => (is => 'ro', isa => 'Paws::EC2::AttributeBooleanValue', xmlname => 'enableDnsSupport', traits => ['Unwrapped',]);
  has VpcId => (is => 'ro', isa => 'Str', xmlname => 'vpcId', traits => ['Unwrapped',]);

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::DescribeVpcAttributeResult

=head1 ATTRIBUTES

=head2 EnableDnsHostnames => Paws::EC2::AttributeBooleanValue

  

Indicates whether the instances launched in the VPC get DNS hostnames.
If this attribute is C<true>, instances in the VPC get DNS hostnames;
otherwise, they do not.









=head2 EnableDnsSupport => Paws::EC2::AttributeBooleanValue

  

Indicates whether DNS resolution is enabled for the VPC. If this
attribute is C<true>, the Amazon DNS server resolves DNS hostnames for
your instances to their corresponding IP addresses; otherwise, it does
not.









=head2 VpcId => Str

  

The ID of the VPC.











=cut

