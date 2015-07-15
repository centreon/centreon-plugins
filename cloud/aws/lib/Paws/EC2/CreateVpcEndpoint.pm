
package Paws::EC2::CreateVpcEndpoint {
  use Moose;
  has ClientToken => (is => 'ro', isa => 'Str');
  has DryRun => (is => 'ro', isa => 'Bool');
  has PolicyDocument => (is => 'ro', isa => 'Str');
  has RouteTableIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'RouteTableId' );
  has ServiceName => (is => 'ro', isa => 'Str', required => 1);
  has VpcId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateVpcEndpoint');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::CreateVpcEndpointResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CreateVpcEndpoint - Arguments for method CreateVpcEndpoint on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateVpcEndpoint on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method CreateVpcEndpoint.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateVpcEndpoint.

As an example:

  $service_obj->CreateVpcEndpoint(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 ClientToken => Str

  

Unique, case-sensitive identifier you provide to ensure the idempotency
of the request. For more information, see How to Ensure Idempotency.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 PolicyDocument => Str

  

A policy to attach to the endpoint that controls access to the service.
The policy must be in valid JSON format. If this parameter is not
specified, we attach a default policy that allows full access to the
service.










=head2 RouteTableIds => ArrayRef[Str]

  

One or more route table IDs.










=head2 B<REQUIRED> ServiceName => Str

  

The AWS service name, in the form
com.amazonaws.E<lt>regionE<gt>.E<lt>serviceE<gt>. To get a list of
available services, use the DescribeVpcEndpointServices request.










=head2 B<REQUIRED> VpcId => Str

  

The ID of the VPC in which the endpoint will be used.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateVpcEndpoint in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

