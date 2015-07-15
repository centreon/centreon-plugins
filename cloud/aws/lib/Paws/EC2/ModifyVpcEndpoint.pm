
package Paws::EC2::ModifyVpcEndpoint {
  use Moose;
  has AddRouteTableIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'AddRouteTableId' );
  has DryRun => (is => 'ro', isa => 'Bool');
  has PolicyDocument => (is => 'ro', isa => 'Str');
  has RemoveRouteTableIds => (is => 'ro', isa => 'ArrayRef[Str]', traits => ['NameInRequest'], request_name => 'RemoveRouteTableId' );
  has ResetPolicy => (is => 'ro', isa => 'Bool');
  has VpcEndpointId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ModifyVpcEndpoint');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::EC2::ModifyVpcEndpointResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::ModifyVpcEndpoint - Arguments for method ModifyVpcEndpoint on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method ModifyVpcEndpoint on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method ModifyVpcEndpoint.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ModifyVpcEndpoint.

As an example:

  $service_obj->ModifyVpcEndpoint(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 AddRouteTableIds => ArrayRef[Str]

  

One or more route tables IDs to associate with the endpoint.










=head2 DryRun => Bool

  

Checks whether you have the required permissions for the action,
without actually making the request, and provides an error response. If
you have the required permissions, the error response is
C<DryRunOperation>. Otherwise, it is C<UnauthorizedOperation>.










=head2 PolicyDocument => Str

  

A policy document to attach to the endpoint. The policy must be in
valid JSON format.










=head2 RemoveRouteTableIds => ArrayRef[Str]

  

One or more route table IDs to disassociate from the endpoint.










=head2 ResetPolicy => Bool

  

Specify C<true> to reset the policy document to the default policy. The
default policy allows access to the service.










=head2 B<REQUIRED> VpcEndpointId => Str

  

The ID of the endpoint.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ModifyVpcEndpoint in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

