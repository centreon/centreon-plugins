
package Paws::CloudSearch::DefineExpression {
  use Moose;
  has DomainName => (is => 'ro', isa => 'Str', required => 1);
  has Expression => (is => 'ro', isa => 'Paws::CloudSearch::Expression', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DefineExpression');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudSearch::DefineExpressionResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'DefineExpressionResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudSearch::DefineExpression - Arguments for method DefineExpression on Paws::CloudSearch

=head1 DESCRIPTION

This class represents the parameters used for calling the method DefineExpression on the 
Amazon CloudSearch service. Use the attributes of this class
as arguments to method DefineExpression.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DefineExpression.

As an example:

  $service_obj->DefineExpression(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> DomainName => Str

  

=head2 B<REQUIRED> Expression => Paws::CloudSearch::Expression

  



=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DefineExpression in L<Paws::CloudSearch>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

