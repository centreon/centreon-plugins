
package Paws::WorkSpaces::DescribeWorkspaceBundles {
  use Moose;
  has BundleIds => (is => 'ro', isa => 'ArrayRef[Str]');
  has NextToken => (is => 'ro', isa => 'Str');
  has Owner => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeWorkspaceBundles');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::WorkSpaces::DescribeWorkspaceBundlesResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::WorkSpaces::DescribeWorkspaceBundles - Arguments for method DescribeWorkspaceBundles on Paws::WorkSpaces

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeWorkspaceBundles on the 
Amazon WorkSpaces service. Use the attributes of this class
as arguments to method DescribeWorkspaceBundles.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeWorkspaceBundles.

As an example:

  $service_obj->DescribeWorkspaceBundles(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 BundleIds => ArrayRef[Str]

  

An array of strings that contains the identifiers of the bundles to
retrieve. This parameter cannot be combined with any other filter
parameter.










=head2 NextToken => Str

  

The C<NextToken> value from a previous call to this operation. Pass
null if this is the first call.










=head2 Owner => Str

  

The owner of the bundles to retrieve. This parameter cannot be combined
with any other filter parameter.

This contains one of the following values:

=over

=item * null - Retrieves the bundles that belong to the account making
the call.

=item * C<AMAZON> - Retrieves the bundles that are provided by AWS.

=back












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeWorkspaceBundles in L<Paws::WorkSpaces>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

