
package Paws::EC2::CreateVpc {
  use Moose;
  has CidrBlock => (is => 'ro', isa => 'Str', required => 1);
  has DryRun => (is => 'ro', isa => 'Bool', traits => ['NameInRequest'], request_name => 'dryRun' );
  has InstanceTenancy => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'instanceTenancy' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateVpc');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::CreateVpcResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateVpc - Arguments for method CreateVpc on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateVpc on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method CreateVpc.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateVpc.

As an example:

  $service_obj->CreateVpc(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> CidrBlock => Str

  

The network range for the VPC, in CIDR notation. For example,
C<10.0.0.0/16>.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 InstanceTenancy => Str

  

The supported tenancy options for instances launched into the VPC. A
value of C<default> means that instances can be launched with any
tenancy; a value of C<dedicated> means all instances launched into the
VPC are launched as dedicated tenancy instances regardless of the
tenancy assigned to the instance at launch. Dedicated tenancy instances
run on single-tenant hardware.

Default: C<default>












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateVpc in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

