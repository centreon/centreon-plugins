
package Paws::CloudFormation::ValidateTemplate {
  use Moose;
  has TemplateBody => (is => 'ro', isa => 'Str');
  has TemplateURL => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ValidateTemplate');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CloudFormation::ValidateTemplateOutput');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'ValidateTemplateResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFormation::ValidateTemplate - Arguments for method ValidateTemplate on Paws::CloudFormation

=head1 DESCRIPTION

This class represents the parameters used for calling the method ValidateTemplate on the 
AWS CloudFormation service. Use the attributes of this class
as arguments to method ValidateTemplate.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ValidateTemplate.

As an example:

  $service_obj->ValidateTemplate(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 TemplateBody => Str

  

Structure containing the template body with a minimum length of 1 byte
and a maximum length of 51,200 bytes. For more information, go to
Template Anatomy in the AWS CloudFormation User Guide.

Conditional: You must pass C<TemplateURL> or C<TemplateBody>. If both
are passed, only C<TemplateBody> is used.










=head2 TemplateURL => Str

  

Location of file containing the template body. The URL must point to a
template (max size: 460,800 bytes) located in an S3 bucket in the same
region as the stack. For more information, go to Template Anatomy in
the AWS CloudFormation User Guide.

Conditional: You must pass C<TemplateURL> or C<TemplateBody>. If both
are passed, only C<TemplateBody> is used.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ValidateTemplate in L<Paws::CloudFormation>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

