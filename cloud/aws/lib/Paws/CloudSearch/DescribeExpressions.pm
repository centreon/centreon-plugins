
package Paws::CloudSearch::DescribeExpressions {
  use Moose;
  has Deployed => (is => 'ro', isa => 'Bool');
  has DomainName => (is => 'ro', isa => 'Str', required => 1);
  has ExpressionNames => (is => 'ro', isa => 'ArrayRef[Str]');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribeExpressions');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudSearch::DescribeExpressionsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DescribeExpressionsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DescribeExpressions - Arguments for method DescribeExpressions on Paws::CloudSearch

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribeExpressions on the 
Amazon CloudSearch service. Use the attributes of this class
as arguments to method DescribeExpressions.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribeExpressions.

As an example:

  $service_obj->DescribeExpressions(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Deployed => Bool

  

Whether to display the deployed configuration (C<true>) or include any
pending changes (C<false>). Defaults to C<false>.










=head2 B<REQUIRED> DomainName => Str

  

The name of the domain you want to describe.










=head2 ExpressionNames => ArrayRef[Str]

  

Limits the C<DescribeExpressions> response to the specified
expressions. If not specified, all expressions are shown.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribeExpressions in L<Paws::CloudSearch>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

