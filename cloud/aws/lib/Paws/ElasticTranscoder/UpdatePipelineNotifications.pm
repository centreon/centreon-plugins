
package Paws::ElasticTranscoder::UpdatePipelineNotifications {
  use Moose;
  has Id => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'Id' , required => 1);
  has Notifications => (is => 'ro', isa => 'Paws::ElasticTranscoder::Notifications', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'UpdatePipelineNotifications');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2012-09-25/pipelines/{Id}/notifications');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'POST');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::ElasticTranscoder::UpdatePipelineNotificationsResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'UpdatePipelineNotificationsResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticTranscoder::UpdatePipelineNotifications - Arguments for method UpdatePipelineNotifications on Paws::ElasticTranscoder

=head1 DESCRIPTION

This class represents the parameters used for calling the method UpdatePipelineNotifications on the 
Amazon Elastic Transcoder service. Use the attributes of this class
as arguments to method UpdatePipelineNotifications.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to UpdatePipelineNotifications.

As an example:

  $service_obj->UpdatePipelineNotifications(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Id => Str

  

The identifier of the pipeline for which you want to change
notification settings.










=head2 B<REQUIRED> Notifications => Paws::ElasticTranscoder::Notifications

  

The topic ARN for the Amazon Simple Notification Service (Amazon SNS)
topic that you want to notify to report job status.

To receive notifications, you must also subscribe to the new topic in
the Amazon SNS console.

=over

=item * B<Progressing>: The topic ARN for the Amazon Simple
Notification Service (Amazon SNS) topic that you want to notify when
Elastic Transcoder has started to process jobs that are added to this
pipeline. This is the ARN that Amazon SNS returned when you created the
topic.

=item * B<Completed>: The topic ARN for the Amazon SNS topic that you
want to notify when Elastic Transcoder has finished processing a job.
This is the ARN that Amazon SNS returned when you created the topic.

=item * B<Warning>: The topic ARN for the Amazon SNS topic that you
want to notify when Elastic Transcoder encounters a warning condition.
This is the ARN that Amazon SNS returned when you created the topic.

=item * B<Error>: The topic ARN for the Amazon SNS topic that you want
to notify when Elastic Transcoder encounters an error condition. This
is the ARN that Amazon SNS returned when you created the topic.

=back












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method UpdatePipelineNotifications in L<Paws::ElasticTranscoder>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

