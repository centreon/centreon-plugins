
package Paws::OpsWorks::DescribeLayers {
  use Moose;
  has LayerIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has StackId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeLayers');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::OpsWorks::DescribeLayersResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribeLayers - Arguments for method DescribeLayers on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeLayers on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method DescribeLayers.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeLayers.

As an example:

  $service_obj->DescribeLayers(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 LayerIds => ArrayRef[Str]

  

An array of layer IDs that specify the layers to be described. If you
omit this parameter, C<DescribeLayers> returns a description of every
layer in the specified stack.










=head2 StackId => Str

  

The stack ID.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeLayers in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

