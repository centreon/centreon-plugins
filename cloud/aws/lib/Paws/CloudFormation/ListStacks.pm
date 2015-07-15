
package Paws::CloudFormation::ListStacks {
  use Moose;
  has NextToken => (is => 'ro', isa => 'Str');
  has StackStatusFilter => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListStacks');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudFormation::ListStacksOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListStacksResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFormation::ListStacks - Arguments for method ListStacks on Paws::CloudFormation

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListStacks on the 
AWS CloudFormation service. Use the attributes of this class
as arguments to method ListStacks.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListStacks.

As an example:

  $service_obj->ListStacks(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 NextToken => Str

  

String that identifies the start of the next list of stacks, if there
is one.

Default: There is no default value.










=head2 StackStatusFilter => ArrayRef[Str]

  

Stack status to use as a filter. Specify one or more stack status codes
to list only stacks with the specified status codes. For a complete
list of stack status codes, see the C<StackStatus> parameter of the
Stack data type.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListStacks in L<Paws::CloudFormation>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

