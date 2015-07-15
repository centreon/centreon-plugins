
package Paws::Lambda::ListEventSourceMappings {
  use Moose;
  has EventSourceArn => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'EventSourceArn' );
  has FunctionName => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'FunctionName' );
  has Marker => (is => 'ro', isa => 'Str', traits => ['ParamInQuery'], query_name => 'Marker' );
  has MaxItems => (is => 'ro', isa => 'Int', traits => ['ParamInQuery'], query_name => 'MaxItems' );

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListEventSourceMappings');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2015-03-31/event-source-mappings/');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'GET');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::Lambda::ListEventSourceMappingsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ListEventSourceMappingsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Lambda::ListEventSourceMappings - Arguments for method ListEventSourceMappings on Paws::Lambda

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListEventSourceMappings on the 
AWS Lambda service. Use the attributes of this class
as arguments to method ListEventSourceMappings.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListEventSourceMappings.

As an example:

  $service_obj->ListEventSourceMappings(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 EventSourceArn => Str

  

The Amazon Resource Name (ARN) of the Amazon Kinesis stream.










=head2 FunctionName => Str

  

The name of the Lambda function.

You can specify an unqualified function name (for example, "Thumbnail")
or you can specify Amazon Resource Name (ARN) of the function (for
example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS
Lambda also allows you to specify only the account ID qualifier (for
example, "account-id:Thumbnail"). Note that the length constraint
applies only to the ARN. If you specify only the function name, it is
limited to 64 character in length.










=head2 Marker => Str

  

Optional string. An opaque pagination token returned from a previous
C<ListEventSourceMappings> operation. If present, specifies to continue
the list from where the returning call left off.










=head2 MaxItems => Int

  

Optional integer. Specifies the maximum number of event sources to
return in response. This value must be greater than 0.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListEventSourceMappings in L<Paws::Lambda>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

