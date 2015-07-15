
package Paws::EC2::CancelExportTask {
  use Moose;
  has ExportTaskId => (is => 'ro', isa => 'Str', traits => ['NameInRequest'], request_name => 'exportTaskId' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CancelExportTask');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::EC2::CancelExportTask - Arguments for method CancelExportTask on Paws::EC2

=head1 DESCRIPTION

This class represents the parameters used for calling the method CancelExportTask on the 
Amazon Elastic Compute Cloud service. Use the attributes of this class
as arguments to method CancelExportTask.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CancelExportTask.

As an example:

  $service_obj->CancelExportTask(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ExportTaskId => Str

  

The ID of the export task. This is the ID returned by
C<CreateInstanceExportTask>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CancelExportTask in L<Paws::EC2>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

