
package Paws::CloudFormation::UpdateStack {
  use Moose;
  has Capabilities => (is => 'ro', isa => 'ArrayRef[Str]');
  has NotificationARNs => (is => 'ro', isa => 'ArrayRef[Str]');
  has Parameters => (is => 'ro', isa => 'ArrayRef[Paws::CloudFormation::Parameter]');
  has StackName => (is => 'ro', isa => 'Str', required => 1);
  has StackPolicyBody => (is => 'ro', isa => 'Str');
  has StackPolicyDuringUpdateBody => (is => 'ro', isa => 'Str');
  has StackPolicyDuringUpdateURL => (is => 'ro', isa => 'Str');
  has StackPolicyURL => (is => 'ro', isa => 'Str');
  has TemplateBody => (is => 'ro', isa => 'Str');
  has TemplateURL => (is => 'ro', isa => 'Str');
  has UsePreviousTemplate => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdateStack');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudFormation::UpdateStackOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'UpdateStackResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFormation::UpdateStack - Arguments for method UpdateStack on Paws::CloudFormation

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdateStack on the 
AWS CloudFormation service. Use the attributes of this class
as arguments to method UpdateStack.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdateStack.

As an example:

  $service_obj->UpdateStack(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 Capabilities => ArrayRef[Str]

  

A list of capabilities that you must specify before AWS CloudFormation
can create or update certain stacks. Some stack templates might include
resources that can affect permissions in your AWS account. For those
stacks, you must explicitly acknowledge their capabilities by
specifying this parameter. Currently, the only valid value is
C<CAPABILITY_IAM>, which is required for the following resources:
AWS::IAM::AccessKey, AWS::IAM::Group, AWS::IAM::InstanceProfile,
AWS::IAM::Policy, AWS::IAM::Role, AWS::IAM::User, and
AWS::IAM::UserToGroupAddition. If your stack template contains these
resources, we recommend that you review any permissions associated with
them. If you don't specify this parameter, this action returns an
InsufficientCapabilities error.










=head2 NotificationARNs => ArrayRef[Str]

  

Update the ARNs for the Amazon SNS topics that are associated with the
stack.










=head2 Parameters => ArrayRef[Paws::CloudFormation::Parameter]

  

A list of C<Parameter> structures that specify input parameters for the
stack. For more information, see the Parameter data type.










=head2 B<REQUIRED> StackName => Str

  

The name or unique stack ID of the stack to update.










=head2 StackPolicyBody => Str

  

Structure containing a new stack policy body. You can specify either
the C<StackPolicyBody> or the C<StackPolicyURL> parameter, but not
both.

You might update the stack policy, for example, in order to protect a
new resource that you created during a stack update. If you do not
specify a stack policy, the current policy that is associated with the
stack is unchanged.










=head2 StackPolicyDuringUpdateBody => Str

  

Structure containing the temporary overriding stack policy body. You
can specify either the C<StackPolicyDuringUpdateBody> or the
C<StackPolicyDuringUpdateURL> parameter, but not both.

If you want to update protected resources, specify a temporary
overriding stack policy during this update. If you do not specify a
stack policy, the current policy that is associated with the stack will
be used.










=head2 StackPolicyDuringUpdateURL => Str

  

Location of a file containing the temporary overriding stack policy.
The URL must point to a policy (max size: 16KB) located in an S3 bucket
in the same region as the stack. You can specify either the
C<StackPolicyDuringUpdateBody> or the C<StackPolicyDuringUpdateURL>
parameter, but not both.

If you want to update protected resources, specify a temporary
overriding stack policy during this update. If you do not specify a
stack policy, the current policy that is associated with the stack will
be used.










=head2 StackPolicyURL => Str

  

Location of a file containing the updated stack policy. The URL must
point to a policy (max size: 16KB) located in an S3 bucket in the same
region as the stack. You can specify either the C<StackPolicyBody> or
the C<StackPolicyURL> parameter, but not both.

You might update the stack policy, for example, in order to protect a
new resource that you created during a stack update. If you do not
specify a stack policy, the current policy that is associated with the
stack is unchanged.










=head2 TemplateBody => Str

  

Structure containing the template body with a minimum length of 1 byte
and a maximum length of 51,200 bytes. (For more information, go to
Template Anatomy in the AWS CloudFormation User Guide.)

Conditional: You must specify either the C<TemplateBody> or the
C<TemplateURL> parameter, but not both.










=head2 TemplateURL => Str

  

Location of file containing the template body. The URL must point to a
template located in an S3 bucket in the same region as the stack. For
more information, go to Template Anatomy in the AWS CloudFormation User
Guide.

Conditional: You must specify either the C<TemplateBody> or the
C<TemplateURL> parameter, but not both.










=head2 UsePreviousTemplate => Bool

  

Reuse the existing template that is associated with the stack that you
are updating.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdateStack in L<Paws::CloudFormation>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

