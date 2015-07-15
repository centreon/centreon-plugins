
package Paws::EC2::ModifyNetworkInterfaceAttribute {
  use Moose;
  has Attachment => (is => 'ro', isa => 'Paws::EC2::NetworkInterfaceAttachmentChanges', traits => ['NameInRequest'], request_name => 'attachment' );
  has Description => (is => 'ro', isa => 'Paws::EC2::AttributeValue', traits => ['NameInRequest'], request_name => 'description' );
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has Groups => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'SecurityGroupId' );
  has NetworkInterfaceId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'networkInterfaceId' , required => 1);
  has SourceDestCheck => (is => 'ro', isa => 'Paws::EC2::AttributeBooleanValue', traits => ['NameInRequest'], request_name => 'sourceDestCheck' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyNetworkInterfaceAttribute');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ModifyNetworkInterfaceAttribute - Arguments for method ModifyNetworkInterfaceAttribute on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyNetworkInterfaceAttribute on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method ModifyNetworkInterfaceAttribute.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyNetworkInterfaceAttribute.

As an example:

  $service_obj->ModifyNetworkInterfaceAttribute(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Attachment => Paws::EC2::NetworkInterfaceAttachmentChanges

  

Information about the interface attachment. If modifying the 'delete on
termination' attribute, you must specify the ID of the interface
attachment.










=head2 Description => Paws::EC2::AttributeValue

  

A description for the network interface.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 Groups => ArrayRef[Str]

  

Changes the security groups for the network interface. The new set of
groups you specify replaces the current set. You must specify at least
one group, even if it's just the default security group in the VPC. You
must specify the ID of the security group, not the name.










=head2 B<REQUIRED> NetworkInterfaceId => Str

  

The ID of the network interface.










=head2 SourceDestCheck => Paws::EC2::AttributeBooleanValue

  

Indicates whether source/destination checking is enabled. A value of
C<true> means checking is enabled, and C<false> means checking is
disabled. This value must be C<false> for a NAT instance to perform
NAT. For more information, see NAT Instances in the I<Amazon Virtual
Private Cloud User Guide>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyNetworkInterfaceAttribute in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

