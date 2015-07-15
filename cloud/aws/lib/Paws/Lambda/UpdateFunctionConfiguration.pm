
package Paws::Lambda::UpdateFunctionConfiguration {
  use Moose;
  has Description => (is => 'ro', isa => 'Str');
  has FunctionName => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'FunctionName' , required => 1);
  has Handler => (is => 'ro', isa => 'Str');
  has MemorySize => (is => 'ro', isa => 'Int');
  has Role => (is => 'ro', isa => 'Str');
  has Timeout => (is => 'ro', isa => 'Int');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateFunctionConfiguration');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2015-03-31/functions/{FunctionName}/versions/HEAD/configuration');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'PUT');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Lambda::FunctionConfiguration');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'UpdateFunctionConfigurationResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Lambda::UpdateFunctionConfiguration - Arguments for method UpdateFunctionConfiguration on Paws::Lambda

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateFunctionConfiguration on the 
AWS Lambda service. Use the attributes of this class
as arguments to method UpdateFunctionConfiguration.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateFunctionConfiguration.

As an example:

  $service_obj->UpdateFunctionConfiguration(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Description => Str

  

A short user-defined function description. AWS Lambda does not use this
value. Assign a meaningful description as you see fit.










=head2 B<REQUIRED> FunctionName => Str

  

The name of the Lambda function.

You can specify an unqualified function name (for example, "Thumbnail")
or you can specify Amazon Resource Name (ARN) of the function (for
example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS
Lambda also allows you to specify only the account ID qualifier (for
example, "account-id:Thumbnail"). Note that the length constraint
applies only to the ARN. If you specify only the function name, it is
limited to 64 character in length.










=head2 Handler => Str

  

The function that Lambda calls to begin executing your function. For
Node.js, it is the I<module-name.export> value in your function.










=head2 MemorySize => Int

  

The amount of memory, in MB, your Lambda function is given. AWS Lambda
uses this memory size to infer the amount of CPU allocated to your
function. Your function use-case determines your CPU and memory
requirements. For example, a database operation might need less memory
compared to an image processing function. The default value is 128 MB.
The value must be a multiple of 64 MB.










=head2 Role => Str

  

The Amazon Resource Name (ARN) of the IAM role that Lambda will assume
when it executes your function.










=head2 Timeout => Int

  

The function execution time at which AWS Lambda should terminate the
function. Because the execution time has cost implications, we
recommend you set this value based on your expected execution time. The
default is 3 seconds.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateFunctionConfiguration in L<Paws::Lambda>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

