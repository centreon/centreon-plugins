package Paws::CloudFormation {
  use Moose;
  sub service { 'cloudformation' }
  sub version { '2010-05-15' }
  sub flattened_arrays { 0 }

  with 'Paws::API::Caller', 'Paws::API::RegionalEndpointCaller', 'Paws::Net::V4Signature', 'Paws::Net::QueryCaller', 'Paws::Net::XMLResponse';

  
  sub CancelUpdateStack {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::CancelUpdateStack', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateStack {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::CreateStack', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteStack {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::DeleteStack', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeStackEvents {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::DescribeStackEvents', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeStackResource {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::DescribeStackResource', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeStackResources {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::DescribeStackResources', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeStacks {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::DescribeStacks', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub EstimateTemplateCost {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::EstimateTemplateCost', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetStackPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::GetStackPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetTemplate {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::GetTemplate', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetTemplateSummary {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::GetTemplateSummary', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListStackResources {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::ListStackResources', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListStacks {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::ListStacks', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SetStackPolicy {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::SetStackPolicy', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SignalResource {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::SignalResource', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateStack {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::UpdateStack', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ValidateTemplate {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudFormation::ValidateTemplate', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFormation - Perl Interface to AWS AWS CloudFormation

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('CloudFormation')->new;
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



AWS CloudFormation

AWS CloudFormation enables you to create and manage AWS infrastructure
deployments predictably and repeatedly. AWS CloudFormation helps you
leverage AWS products such as Amazon EC2, EBS, Amazon SNS, ELB, and
Auto Scaling to build highly-reliable, highly scalable, cost effective
applications without worrying about creating and configuring the
underlying AWS infrastructure.

With AWS CloudFormation, you declare all of your resources and
dependencies in a template file. The template defines a collection of
resources as a single unit called a stack. AWS CloudFormation creates
and deletes all member resources of the stack together and manages all
dependencies between the resources for you.

For more information about this product, go to the CloudFormation
Product Page.

Amazon CloudFormation makes use of other AWS products. If you need
additional technical information about a specific AWS product, you can
find the product's technical documentation at
http://aws.amazon.com/documentation/.










=head1 METHODS

=head2 CancelUpdateStack(StackName => Str)

Each argument is described in detail in: L<Paws::CloudFormation::CancelUpdateStack>

Returns: nothing

  

Cancels an update on the specified stack. If the call completes
successfully, the stack will roll back the update and revert to the
previous stack configuration.

Only stacks that are in the UPDATE_IN_PROGRESS state can be canceled.











=head2 CreateStack(StackName => Str, [Capabilities => ArrayRef[Str], DisableRollback => Bool, NotificationARNs => ArrayRef[Str], OnFailure => Str, Parameters => ArrayRef[Paws::CloudFormation::Parameter], StackPolicyBody => Str, StackPolicyURL => Str, Tags => ArrayRef[Paws::CloudFormation::Tag], TemplateBody => Str, TemplateURL => Str, TimeoutInMinutes => Int])

Each argument is described in detail in: L<Paws::CloudFormation::CreateStack>

Returns: a L<Paws::CloudFormation::CreateStackOutput> instance

  

Creates a stack as specified in the template. After the call completes
successfully, the stack creation starts. You can check the status of
the stack via the DescribeStacks API.











=head2 DeleteStack(StackName => Str)

Each argument is described in detail in: L<Paws::CloudFormation::DeleteStack>

Returns: nothing

  

Deletes a specified stack. Once the call completes successfully, stack
deletion starts. Deleted stacks do not show up in the DescribeStacks
API if the deletion has been completed successfully.











=head2 DescribeStackEvents([NextToken => Str, StackName => Str])

Each argument is described in detail in: L<Paws::CloudFormation::DescribeStackEvents>

Returns: a L<Paws::CloudFormation::DescribeStackEventsOutput> instance

  

Returns all stack related events for a specified stack. For more
information about a stack's event history, go to Stacks in the AWS
CloudFormation User Guide.

You can list events for stacks that have failed to create or have been
deleted by specifying the unique stack identifier (stack ID).











=head2 DescribeStackResource(LogicalResourceId => Str, StackName => Str)

Each argument is described in detail in: L<Paws::CloudFormation::DescribeStackResource>

Returns: a L<Paws::CloudFormation::DescribeStackResourceOutput> instance

  

Returns a description of the specified resource in the specified stack.

For deleted stacks, DescribeStackResource returns resource information
for up to 90 days after the stack has been deleted.











=head2 DescribeStackResources([LogicalResourceId => Str, PhysicalResourceId => Str, StackName => Str])

Each argument is described in detail in: L<Paws::CloudFormation::DescribeStackResources>

Returns: a L<Paws::CloudFormation::DescribeStackResourcesOutput> instance

  

Returns AWS resource descriptions for running and deleted stacks. If
C<StackName> is specified, all the associated resources that are part
of the stack are returned. If C<PhysicalResourceId> is specified, the
associated resources of the stack that the resource belongs to are
returned.

Only the first 100 resources will be returned. If your stack has more
resources than this, you should use C<ListStackResources> instead.

For deleted stacks, C<DescribeStackResources> returns resource
information for up to 90 days after the stack has been deleted.

You must specify either C<StackName> or C<PhysicalResourceId>, but not
both. In addition, you can specify C<LogicalResourceId> to filter the
returned result. For more information about resources, the
C<LogicalResourceId> and C<PhysicalResourceId>, go to the AWS
CloudFormation User Guide.

A C<ValidationError> is returned if you specify both C<StackName> and
C<PhysicalResourceId> in the same request.











=head2 DescribeStacks([NextToken => Str, StackName => Str])

Each argument is described in detail in: L<Paws::CloudFormation::DescribeStacks>

Returns: a L<Paws::CloudFormation::DescribeStacksOutput> instance

  

Returns the description for the specified stack; if no stack name was
specified, then it returns the description for all the stacks created.











=head2 EstimateTemplateCost([Parameters => ArrayRef[Paws::CloudFormation::Parameter], TemplateBody => Str, TemplateURL => Str])

Each argument is described in detail in: L<Paws::CloudFormation::EstimateTemplateCost>

Returns: a L<Paws::CloudFormation::EstimateTemplateCostOutput> instance

  

Returns the estimated monthly cost of a template. The return value is
an AWS Simple Monthly Calculator URL with a query string that describes
the resources required to run the template.











=head2 GetStackPolicy(StackName => Str)

Each argument is described in detail in: L<Paws::CloudFormation::GetStackPolicy>

Returns: a L<Paws::CloudFormation::GetStackPolicyOutput> instance

  

Returns the stack policy for a specified stack. If a stack doesn't have
a policy, a null value is returned.











=head2 GetTemplate(StackName => Str)

Each argument is described in detail in: L<Paws::CloudFormation::GetTemplate>

Returns: a L<Paws::CloudFormation::GetTemplateOutput> instance

  

Returns the template body for a specified stack. You can get the
template for running or deleted stacks.

For deleted stacks, GetTemplate returns the template for up to 90 days
after the stack has been deleted.

If the template does not exist, a C<ValidationError> is returned.











=head2 GetTemplateSummary([StackName => Str, TemplateBody => Str, TemplateURL => Str])

Each argument is described in detail in: L<Paws::CloudFormation::GetTemplateSummary>

Returns: a L<Paws::CloudFormation::GetTemplateSummaryOutput> instance

  

Returns information about a new or existing template. The
C<GetTemplateSummary> action is useful for viewing parameter
information, such as default parameter values and parameter types,
before you create or update a stack.

You can use the C<GetTemplateSummary> action when you submit a
template, or you can get template information for a running or deleted
stack.

For deleted stacks, C<GetTemplateSummary> returns the template
information for up to 90 days after the stack has been deleted. If the
template does not exist, a C<ValidationError> is returned.











=head2 ListStackResources(StackName => Str, [NextToken => Str])

Each argument is described in detail in: L<Paws::CloudFormation::ListStackResources>

Returns: a L<Paws::CloudFormation::ListStackResourcesOutput> instance

  

Returns descriptions of all resources of the specified stack.

For deleted stacks, ListStackResources returns resource information for
up to 90 days after the stack has been deleted.











=head2 ListStacks([NextToken => Str, StackStatusFilter => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::CloudFormation::ListStacks>

Returns: a L<Paws::CloudFormation::ListStacksOutput> instance

  

Returns the summary information for stacks whose status matches the
specified StackStatusFilter. Summary information for stacks that have
been deleted is kept for 90 days after the stack is deleted. If no
StackStatusFilter is specified, summary information for all stacks is
returned (including existing stacks and stacks that have been deleted).











=head2 SetStackPolicy(StackName => Str, [StackPolicyBody => Str, StackPolicyURL => Str])

Each argument is described in detail in: L<Paws::CloudFormation::SetStackPolicy>

Returns: nothing

  

Sets a stack policy for a specified stack.











=head2 SignalResource(LogicalResourceId => Str, StackName => Str, Status => Str, UniqueId => Str)

Each argument is described in detail in: L<Paws::CloudFormation::SignalResource>

Returns: nothing

  

Sends a signal to the specified resource with a success or failure
status. You can use the SignalResource API in conjunction with a
creation policy or update policy. AWS CloudFormation doesn't proceed
with a stack creation or update until resources receive the required
number of signals or the timeout period is exceeded. The SignalResource
API is useful in cases where you want to send signals from anywhere
other than an Amazon EC2 instance.











=head2 UpdateStack(StackName => Str, [Capabilities => ArrayRef[Str], NotificationARNs => ArrayRef[Str], Parameters => ArrayRef[Paws::CloudFormation::Parameter], StackPolicyBody => Str, StackPolicyDuringUpdateBody => Str, StackPolicyDuringUpdateURL => Str, StackPolicyURL => Str, TemplateBody => Str, TemplateURL => Str, UsePreviousTemplate => Bool])

Each argument is described in detail in: L<Paws::CloudFormation::UpdateStack>

Returns: a L<Paws::CloudFormation::UpdateStackOutput> instance

  

Updates a stack as specified in the template. After the call completes
successfully, the stack update starts. You can check the status of the
stack via the DescribeStacks action.

To get a copy of the template for an existing stack, you can use the
GetTemplate action.

Tags that were associated with this stack during creation time will
still be associated with the stack after an C<UpdateStack> operation.

For more information about creating an update template, updating a
stack, and monitoring the progress of the update, see Updating a Stack.











=head2 ValidateTemplate([TemplateBody => Str, TemplateURL => Str])

Each argument is described in detail in: L<Paws::CloudFormation::ValidateTemplate>

Returns: a L<Paws::CloudFormation::ValidateTemplateOutput> instance

  

Validates a specified template.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

