package Paws::Lambda {
  warn "Paws::Lambda is not stable / supported / entirely developed";
  use Moose;
  sub service { 'lambda' }
  sub version { '2015-03-31' }
  sub flattened_arrays { 0 }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::RestJsonCaller', 'Paws::Net::RestJsonResponse';

  
  sub AddPermission {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::AddPermission', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateEventSourceMapping {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::CreateEventSourceMapping', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateFunction {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::CreateFunction', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteEventSourceMapping {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::DeleteEventSourceMapping', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteFunction {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::DeleteFunction', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetEventSourceMapping {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::GetEventSourceMapping', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetFunction {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::GetFunction', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetFunctionConfiguration {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::GetFunctionConfiguration', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::GetPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub Invoke {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::Invoke', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub InvokeAsync {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::InvokeAsync', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListEventSourceMappings {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::ListEventSourceMappings', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListFunctions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::ListFunctions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RemovePermission {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::RemovePermission', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateEventSourceMapping {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::UpdateEventSourceMapping', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateFunctionCode {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::UpdateFunctionCode', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateFunctionConfiguration {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Lambda::UpdateFunctionConfiguration', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListAllEventSourceMappings {
    my $self = shift;

    my $result = $self->ListEventSourceMappings(@_);
    my $array = [];
    push @$array, @{ $result->EventSourceMappings };

    while ($result->NextMarker) {
      $result = $self->ListEventSourceMappings(@_, Marker => $result->NextMarker);
      push @$array, @{ $result->EventSourceMappings };
    }

    return 'Paws::Lambda::ListEventSourceMappings'->_returns->new(EventSourceMappings => $array);
  }
  sub ListAllFunctions {
    my $self = shift;

    my $result = $self->ListFunctions(@_);
    my $array = [];
    push @$array, @{ $result->Functions };

    while ($result->NextMarker) {
      $result = $self->ListFunctions(@_, Marker => $result->NextMarker);
      push @$array, @{ $result->Functions };
    }

    return 'Paws::Lambda::ListFunctions'->_returns->new(Functions => $array);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Lambda - Perl Interface to AWS AWS Lambda

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('Lambda')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



AWS Lambda

B<Overview>

This is the I<AWS Lambda API Reference>. The AWS Lambda Developer Guide
provides additional information. For the service overview, go to What
is AWS Lambda, and for information about how the service works, go to
AWS Lambda: How it Works in the I<AWS Lambda Developer Guide>.










=head1 METHODS

=head2 AddPermission(Action => Str, FunctionName => Str, Principal => Str, StatementId => Str, [SourceAccount => Str, SourceArn => Str])

Each argument is described in detail in: L<Paws::Lambda::AddPermission>

Returns: a L<Paws::Lambda::AddPermissionResponse> instance

  

Adds a permission to the access policy associated with the specified
AWS Lambda function. In a "push event" model, the access policy
attached to the Lambda function grants Amazon S3 or a user application
permission for the Lambda C<lambda:Invoke> action. For information
about the push model, see AWS Lambda: How it Works. Each Lambda
function has one access policy associated with it. You can use the
C<AddPermission> API to add a permission to the policy. You have one
access policy but it can have multiple permission statements.

This operation requires permission for the C<lambda:AddPermission>
action.











=head2 CreateEventSourceMapping(EventSourceArn => Str, FunctionName => Str, StartingPosition => Str, [BatchSize => Int, Enabled => Bool])

Each argument is described in detail in: L<Paws::Lambda::CreateEventSourceMapping>

Returns: a L<Paws::Lambda::EventSourceMappingConfiguration> instance

  

Identifies a stream as an event source for a Lambda function. It can be
either an Amazon Kinesis stream or an Amazon DynamoDB stream. AWS
Lambda invokes the specified function when records are posted to the
stream.

This is the pull model, where AWS Lambda invokes the function. For more
information, go to AWS Lambda: How it Works in the I<AWS Lambda
Developer Guide>.

This association between an Amazon Kinesis stream and a Lambda function
is called the event source mapping. You provide the configuration
information (for example, which stream to read from and which Lambda
function to invoke) for the event source mapping in the request body.

Each event source, such as an Amazon Kinesis or a DynamoDB stream, can
be associated with multiple AWS Lambda function. A given Lambda
function can be associated with multiple AWS event sources.

This operation requires permission for the
C<lambda:CreateEventSourceMapping> action.











=head2 CreateFunction(Code => Paws::Lambda::FunctionCode, FunctionName => Str, Handler => Str, Role => Str, Runtime => Str, [Description => Str, MemorySize => Int, Timeout => Int])

Each argument is described in detail in: L<Paws::Lambda::CreateFunction>

Returns: a L<Paws::Lambda::FunctionConfiguration> instance

  

Creates a new Lambda function. The function metadata is created from
the request parameters, and the code for the function is provided by a
.zip file in the request body. If the function name already exists, the
operation will fail. Note that the function name is case-sensitive.

This operation requires permission for the C<lambda:CreateFunction>
action.











=head2 DeleteEventSourceMapping(UUID => Str)

Each argument is described in detail in: L<Paws::Lambda::DeleteEventSourceMapping>

Returns: a L<Paws::Lambda::EventSourceMappingConfiguration> instance

  

Removes an event source mapping. This means AWS Lambda will no longer
invoke the function for events in the associated source.

This operation requires permission for the
C<lambda:DeleteEventSourceMapping> action.











=head2 DeleteFunction(FunctionName => Str)

Each argument is described in detail in: L<Paws::Lambda::DeleteFunction>

Returns: nothing

  

Deletes the specified Lambda function code and configuration.

When you delete a function the associated access policy is also
deleted. You will need to delete the event source mappings explicitly.

This operation requires permission for the C<lambda:DeleteFunction>
action.











=head2 GetEventSourceMapping(UUID => Str)

Each argument is described in detail in: L<Paws::Lambda::GetEventSourceMapping>

Returns: a L<Paws::Lambda::EventSourceMappingConfiguration> instance

  

Returns configuration information for the specified event source
mapping (see CreateEventSourceMapping).

This operation requires permission for the
C<lambda:GetEventSourceMapping> action.











=head2 GetFunction(FunctionName => Str)

Each argument is described in detail in: L<Paws::Lambda::GetFunction>

Returns: a L<Paws::Lambda::GetFunctionResponse> instance

  

Returns the configuration information of the Lambda function and a
presigned URL link to the .zip file you uploaded with CreateFunction so
you can download the .zip file. Note that the URL is valid for up to 10
minutes. The configuration information is the same information you
provided as parameters when uploading the function.

This operation requires permission for the C<lambda:GetFunction>
action.











=head2 GetFunctionConfiguration(FunctionName => Str)

Each argument is described in detail in: L<Paws::Lambda::GetFunctionConfiguration>

Returns: a L<Paws::Lambda::FunctionConfiguration> instance

  

Returns the configuration information of the Lambda function. This the
same information you provided as parameters when uploading the function
by using CreateFunction.

This operation requires permission for the
C<lambda:GetFunctionConfiguration> operation.











=head2 GetPolicy(FunctionName => Str)

Each argument is described in detail in: L<Paws::Lambda::GetPolicy>

Returns: a L<Paws::Lambda::GetPolicyResponse> instance

  

Returns the access policy, containing a list of permissions granted via
the C<AddPermission> API, associated with the specified bucket.

You need permission for the C<lambda:GetPolicy action.>











=head2 Invoke(FunctionName => Str, [ClientContext => Str, InvocationType => Str, LogType => Str, Payload => Str])

Each argument is described in detail in: L<Paws::Lambda::Invoke>

Returns: a L<Paws::Lambda::InvocationResponse> instance

  

Invokes a specified Lambda function.

This operation requires permission for the C<lambda:InvokeFunction>
action.











=head2 InvokeAsync(FunctionName => Str, InvokeArgs => Str)

Each argument is described in detail in: L<Paws::Lambda::InvokeAsync>

Returns: a L<Paws::Lambda::InvokeAsyncResponse> instance

  

This API is deprecated. We recommend you use C<Invoke> API (see
Invoke).

Submits an invocation request to AWS Lambda. Upon receiving the
request, Lambda executes the specified function asynchronously. To see
the logs generated by the Lambda function execution, see the CloudWatch
logs console.

This operation requires permission for the C<lambda:InvokeFunction>
action.











=head2 ListEventSourceMappings([EventSourceArn => Str, FunctionName => Str, Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::Lambda::ListEventSourceMappings>

Returns: a L<Paws::Lambda::ListEventSourceMappingsResponse> instance

  

Returns a list of event source mappings you created using the
C<CreateEventSourceMapping> (see CreateEventSourceMapping), where you
identify a stream as an event source. This list does not include Amazon
S3 event sources.

For each mapping, the API returns configuration information. You can
optionally specify filters to retrieve specific event source mappings.

This operation requires permission for the
C<lambda:ListEventSourceMappings> action.











=head2 ListFunctions([Marker => Str, MaxItems => Int])

Each argument is described in detail in: L<Paws::Lambda::ListFunctions>

Returns: a L<Paws::Lambda::ListFunctionsResponse> instance

  

Returns a list of your Lambda functions. For each function, the
response includes the function configuration information. You must use
GetFunction to retrieve the code for your function.

This operation requires permission for the C<lambda:ListFunctions>
action.











=head2 RemovePermission(FunctionName => Str, StatementId => Str)

Each argument is described in detail in: L<Paws::Lambda::RemovePermission>

Returns: nothing

  

You can remove individual permissions from an access policy associated
with a Lambda function by providing a Statement ID.

Note that removal of a permission will cause an active event source to
lose permission to the function.

You need permission for the C<lambda:RemovePermission> action.











=head2 UpdateEventSourceMapping(UUID => Str, [BatchSize => Int, Enabled => Bool, FunctionName => Str])

Each argument is described in detail in: L<Paws::Lambda::UpdateEventSourceMapping>

Returns: a L<Paws::Lambda::EventSourceMappingConfiguration> instance

  

You can update an event source mapping. This is useful if you want to
change the parameters of the existing mapping without losing your
position in the stream. You can change which function will receive the
stream records, but to change the stream itself, you must create a new
mapping.

This operation requires permission for the
C<lambda:UpdateEventSourceMapping> action.











=head2 UpdateFunctionCode(FunctionName => Str, [S3Bucket => Str, S3Key => Str, S3ObjectVersion => Str, ZipFile => Str])

Each argument is described in detail in: L<Paws::Lambda::UpdateFunctionCode>

Returns: a L<Paws::Lambda::FunctionConfiguration> instance

  

Updates the code for the specified Lambda function. This operation must
only be used on an existing Lambda function and cannot be used to
update the function configuration.

This operation requires permission for the C<lambda:UpdateFunctionCode>
action.











=head2 UpdateFunctionConfiguration(FunctionName => Str, [Description => Str, Handler => Str, MemorySize => Int, Role => Str, Timeout => Int])

Each argument is described in detail in: L<Paws::Lambda::UpdateFunctionConfiguration>

Returns: a L<Paws::Lambda::FunctionConfiguration> instance

  

Updates the configuration parameters for the specified Lambda function
by using the values provided in the request. You provide only the
parameters you want to change. This operation must only be used on an
existing Lambda function and cannot be used to update the function's
code.

This operation requires permission for the
C<lambda:UpdateFunctionConfiguration> action.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

