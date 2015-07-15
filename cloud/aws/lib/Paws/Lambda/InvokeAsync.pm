
package Paws::Lambda::InvokeAsync {
  use Moose;
  has FunctionName => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'FunctionName' , required => 1);
  has InvokeArgs => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'InvokeAsync');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2014-11-13/functions/{FunctionName}/invoke-async/');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Lambda::InvokeAsyncResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'InvokeAsyncResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Lambda::InvokeAsync - Arguments for method InvokeAsync on Paws::Lambda

=head1 DESCRIPTION

This class represents the parameters used for calling the method InvokeAsync on the 
AWS Lambda service. Use the attributes of this class
as arguments to method InvokeAsync.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to InvokeAsync.

As an example:

  $service_obj->InvokeAsync(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> FunctionName => Str

  

The Lambda function name.










=head2 B<REQUIRED> InvokeArgs => Str

  

JSON that you want to provide to your Lambda function as input.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method InvokeAsync in L<Paws::Lambda>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

