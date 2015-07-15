
package Paws::DataPipeline::SetStatus {
  use Moose;
  has objectIds => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has pipelineId => (is => 'ro', isa => 'Str', required => 1);
  has status => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SetStatus');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::DataPipeline::SetStatus - Arguments for method SetStatus on Paws::DataPipeline

=head1 DESCRIPTION

This class represents the parameters used for calling the method SetStatus on the 
AWS Data Pipeline service. Use the attributes of this class
as arguments to method SetStatus.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SetStatus.

As an example:

  $service_obj->SetStatus(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> objectIds => ArrayRef[Str]

  

The IDs of the objects. The corresponding objects can be either
physical or components, but not a mix of both types.










=head2 B<REQUIRED> pipelineId => Str

  

The ID of the pipeline that contains the objects.










=head2 B<REQUIRED> status => Str

  

The status to be set on all the objects specified in C<objectIds>. For
components, use C<PAUSE> or C<RESUME>. For instances, use
C<TRY_CANCEL>, C<RERUN>, or C<MARK_FINISHED>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SetStatus in L<Paws::DataPipeline>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

