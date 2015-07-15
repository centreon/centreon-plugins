
package Paws::EC2::ModifyVpcAttribute {
  use Moose;
  has EnableDnsHostnames => (is => 'ro', isa => 'Paws::EC2::AttributeBooleanValue');
  has EnableDnsSupport => (is => 'ro', isa => 'Paws::EC2::AttributeBooleanValue');
  has VpcId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'vpcId' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyVpcAttribute');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ModifyVpcAttribute - Arguments for method ModifyVpcAttribute on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyVpcAttribute on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method ModifyVpcAttribute.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyVpcAttribute.

As an example:

  $service_obj->ModifyVpcAttribute(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 EnableDnsHostnames => Paws::EC2::AttributeBooleanValue

  

Indicates whether the instances launched in the VPC get DNS hostnames.
If enabled, instances in the VPC get DNS hostnames; otherwise, they do
not.

You can only enable DNS hostnames if you also enable DNS support.










=head2 EnableDnsSupport => Paws::EC2::AttributeBooleanValue

  

Indicates whether the DNS resolution is supported for the VPC. If
enabled, queries to the Amazon provided DNS server at the
169.254.169.253 IP address, or the reserved IP address at the base of
the VPC network range "plus two" will succeed. If disabled, the Amazon
provided DNS service in the VPC that resolves public DNS hostnames to
IP addresses is not enabled.










=head2 B<REQUIRED> VpcId => Str

  

The ID of the VPC.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyVpcAttribute in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

