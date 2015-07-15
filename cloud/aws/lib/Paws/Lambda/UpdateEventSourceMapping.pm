
package Paws::Lambda::UpdateEventSourceMapping {
  use Moose;
  has BatchSize => (is => 'ro', isa => 'Int');
  has Enabled => (is => 'ro', isa => 'Bool');
  has FunctionName => (is => 'ro', isa => 'Str');
  has UUID => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'UUID' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateEventSourceMapping');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2015-03-31/event-source-mappings/{UUID}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'PUT');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Lambda::EventSourceMappingConfiguration');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'UpdateEventSourceMappingResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Lambda::UpdateEventSourceMapping - Arguments for method UpdateEventSourceMapping on Paws::Lambda

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateEventSourceMapping on the 
AWS Lambda service. Use the attributes of this class
as arguments to method UpdateEventSourceMapping.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateEventSourceMapping.

As an example:

  $service_obj->UpdateEventSourceMapping(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 BatchSize => Int

  

The maximum number of stream records that can be sent to your Lambda
function for a single invocation.










=head2 Enabled => Bool

  

Specifies whether AWS Lambda should actively poll the stream or not. If
disabled, AWS Lambda will not poll the stream.










=head2 FunctionName => Str

  

The Lambda function to which you want the stream records sent.

You can specify an unqualified function name (for example, "Thumbnail")
or you can specify Amazon Resource Name (ARN) of the function (for
example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS
Lambda also allows you to specify only the account ID qualifier (for
example, "account-id:Thumbnail"). Note that the length constraint
applies only to the ARN. If you specify only the function name, it is
limited to 64 character in length.










=head2 B<REQUIRED> UUID => Str

  

The event source mapping identifier.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateEventSourceMapping in L<Paws::Lambda>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

