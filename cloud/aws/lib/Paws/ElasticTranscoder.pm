package Paws::ElasticTranscoder {
  warn "Paws::ElasticTranscoder is not stable / supported / entirely developed";
  use Moose;
  sub service { 'elastictranscoder' }
  sub version { '2012-09-25' }
  sub flattened_arrays { 0 }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::RestJsonCaller', 'Paws::Net::RestJsonResponse';

  
  sub CancelJob {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::CancelJob', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateJob {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::CreateJob', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreatePipeline {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::CreatePipeline', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreatePreset {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::CreatePreset', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeletePipeline {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::DeletePipeline', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeletePreset {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::DeletePreset', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListJobsByPipeline {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::ListJobsByPipeline', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListJobsByStatus {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::ListJobsByStatus', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListPipelines {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::ListPipelines', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListPresets {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::ListPresets', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ReadJob {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::ReadJob', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ReadPipeline {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::ReadPipeline', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ReadPreset {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::ReadPreset', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub TestRole {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::TestRole', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdatePipeline {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::UpdatePipeline', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdatePipelineNotifications {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::UpdatePipelineNotifications', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdatePipelineStatus {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ElasticTranscoder::UpdatePipelineStatus', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListAllJobsByPipeline {
    my $self = shift;

    my $result = $self->ListJobsByPipeline(@_);
    my $array = [];
    push @$array, @{ $result->Jobs };

    while ($result->NextPageToken) {
      $result = $self->ListJobsByPipeline(@_, PageToken => $result->NextPageToken);
      push @$array, @{ $result->Jobs };
    }

    return 'Paws::ElasticTranscoder::ListJobsByPipeline'->_returns->new(Jobs => $array);
  }
  sub ListAllJobsByStatus {
    my $self = shift;

    my $result = $self->ListJobsByStatus(@_);
    my $array = [];
    push @$array, @{ $result->Jobs };

    while ($result->NextPageToken) {
      $result = $self->ListJobsByStatus(@_, PageToken => $result->NextPageToken);
      push @$array, @{ $result->Jobs };
    }

    return 'Paws::ElasticTranscoder::ListJobsByStatus'->_returns->new(Jobs => $array);
  }
  sub ListAllPipelines {
    my $self = shift;

    my $result = $self->ListPipelines(@_);
    my $array = [];
    push @$array, @{ $result->Pipelines };

    while ($result->NextPageToken) {
      $result = $self->ListPipelines(@_, PageToken => $result->NextPageToken);
      push @$array, @{ $result->Pipelines };
    }

    return 'Paws::ElasticTranscoder::ListPipelines'->_returns->new(Pipelines => $array);
  }
  sub ListAllPresets {
    my $self = shift;

    my $result = $self->ListPresets(@_);
    my $array = [];
    push @$array, @{ $result->Presets };

    while ($result->NextPageToken) {
      $result = $self->ListPresets(@_, PageToken => $result->NextPageToken);
      push @$array, @{ $result->Presets };
    }

    return 'Paws::ElasticTranscoder::ListPresets'->_returns->new(Presets => $array);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticTranscoder - Perl Interface to AWS Amazon Elastic Transcoder

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('ElasticTranscoder')->new;
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



AWS Elastic Transcoder Service

The AWS Elastic Transcoder Service.










=head1 METHODS

=head2 CancelJob(Id => Str)

Each argument is described in detail in: L<Paws::ElasticTranscoder::CancelJob>

Returns: a L<Paws::ElasticTranscoder::CancelJobResponse> instance

  

The CancelJob operation cancels an unfinished job.

You can only cancel a job that has a status of C<Submitted>. To prevent
a pipeline from starting to process a job while you're getting the job
identifier, use UpdatePipelineStatus to temporarily pause the pipeline.











=head2 CreateJob(Input => Paws::ElasticTranscoder::JobInput, PipelineId => Str, [Output => Paws::ElasticTranscoder::CreateJobOutput, OutputKeyPrefix => Str, Outputs => ArrayRef[Paws::ElasticTranscoder::CreateJobOutput], Playlists => ArrayRef[Paws::ElasticTranscoder::CreateJobPlaylist], UserMetadata => Paws::ElasticTranscoder::UserMetadata])

Each argument is described in detail in: L<Paws::ElasticTranscoder::CreateJob>

Returns: a L<Paws::ElasticTranscoder::CreateJobResponse> instance

  

When you create a job, Elastic Transcoder returns JSON data that
includes the values that you specified plus information about the job
that is created.

If you have specified more than one output for your jobs (for example,
one output for the Kindle Fire and another output for the Apple iPhone
4s), you currently must use the Elastic Transcoder API to list the jobs
(as opposed to the AWS Console).











=head2 CreatePipeline(InputBucket => Str, Name => Str, Role => Str, [AwsKmsKeyArn => Str, ContentConfig => Paws::ElasticTranscoder::PipelineOutputConfig, Notifications => Paws::ElasticTranscoder::Notifications, OutputBucket => Str, ThumbnailConfig => Paws::ElasticTranscoder::PipelineOutputConfig])

Each argument is described in detail in: L<Paws::ElasticTranscoder::CreatePipeline>

Returns: a L<Paws::ElasticTranscoder::CreatePipelineResponse> instance

  

The CreatePipeline operation creates a pipeline with settings that you
specify.











=head2 CreatePreset(Container => Str, Name => Str, [Audio => Paws::ElasticTranscoder::AudioParameters, Description => Str, Thumbnails => Paws::ElasticTranscoder::Thumbnails, Video => Paws::ElasticTranscoder::VideoParameters])

Each argument is described in detail in: L<Paws::ElasticTranscoder::CreatePreset>

Returns: a L<Paws::ElasticTranscoder::CreatePresetResponse> instance

  

The CreatePreset operation creates a preset with settings that you
specify.

Elastic Transcoder checks the CreatePreset settings to ensure that they
meet Elastic Transcoder requirements and to determine whether they
comply with H.264 standards. If your settings are not valid for Elastic
Transcoder, Elastic Transcoder returns an HTTP 400 response
(C<ValidationException>) and does not create the preset. If the
settings are valid for Elastic Transcoder but aren't strictly compliant
with the H.264 standard, Elastic Transcoder creates the preset and
returns a warning message in the response. This helps you determine
whether your settings comply with the H.264 standard while giving you
greater flexibility with respect to the video that Elastic Transcoder
produces.

Elastic Transcoder uses the H.264 video-compression format. For more
information, see the International Telecommunication Union publication
I<Recommendation ITU-T H.264: Advanced video coding for generic
audiovisual services>.











=head2 DeletePipeline(Id => Str)

Each argument is described in detail in: L<Paws::ElasticTranscoder::DeletePipeline>

Returns: a L<Paws::ElasticTranscoder::DeletePipelineResponse> instance

  

The DeletePipeline operation removes a pipeline.

You can only delete a pipeline that has never been used or that is not
currently in use (doesn't contain any active jobs). If the pipeline is
currently in use, C<DeletePipeline> returns an error.











=head2 DeletePreset(Id => Str)

Each argument is described in detail in: L<Paws::ElasticTranscoder::DeletePreset>

Returns: a L<Paws::ElasticTranscoder::DeletePresetResponse> instance

  

The DeletePreset operation removes a preset that you've added in an AWS
region.

You can't delete the default presets that are included with Elastic
Transcoder.











=head2 ListJobsByPipeline(PipelineId => Str, [Ascending => Str, PageToken => Str])

Each argument is described in detail in: L<Paws::ElasticTranscoder::ListJobsByPipeline>

Returns: a L<Paws::ElasticTranscoder::ListJobsByPipelineResponse> instance

  

The ListJobsByPipeline operation gets a list of the jobs currently in a
pipeline.

Elastic Transcoder returns all of the jobs currently in the specified
pipeline. The response body contains one element for each job that
satisfies the search criteria.











=head2 ListJobsByStatus(Status => Str, [Ascending => Str, PageToken => Str])

Each argument is described in detail in: L<Paws::ElasticTranscoder::ListJobsByStatus>

Returns: a L<Paws::ElasticTranscoder::ListJobsByStatusResponse> instance

  

The ListJobsByStatus operation gets a list of jobs that have a
specified status. The response body contains one element for each job
that satisfies the search criteria.











=head2 ListPipelines([Ascending => Str, PageToken => Str])

Each argument is described in detail in: L<Paws::ElasticTranscoder::ListPipelines>

Returns: a L<Paws::ElasticTranscoder::ListPipelinesResponse> instance

  

The ListPipelines operation gets a list of the pipelines associated
with the current AWS account.











=head2 ListPresets([Ascending => Str, PageToken => Str])

Each argument is described in detail in: L<Paws::ElasticTranscoder::ListPresets>

Returns: a L<Paws::ElasticTranscoder::ListPresetsResponse> instance

  

The ListPresets operation gets a list of the default presets included
with Elastic Transcoder and the presets that you've added in an AWS
region.











=head2 ReadJob(Id => Str)

Each argument is described in detail in: L<Paws::ElasticTranscoder::ReadJob>

Returns: a L<Paws::ElasticTranscoder::ReadJobResponse> instance

  

The ReadJob operation returns detailed information about a job.











=head2 ReadPipeline(Id => Str)

Each argument is described in detail in: L<Paws::ElasticTranscoder::ReadPipeline>

Returns: a L<Paws::ElasticTranscoder::ReadPipelineResponse> instance

  

The ReadPipeline operation gets detailed information about a pipeline.











=head2 ReadPreset(Id => Str)

Each argument is described in detail in: L<Paws::ElasticTranscoder::ReadPreset>

Returns: a L<Paws::ElasticTranscoder::ReadPresetResponse> instance

  

The ReadPreset operation gets detailed information about a preset.











=head2 TestRole(InputBucket => Str, OutputBucket => Str, Role => Str, Topics => ArrayRef[Str])

Each argument is described in detail in: L<Paws::ElasticTranscoder::TestRole>

Returns: a L<Paws::ElasticTranscoder::TestRoleResponse> instance

  

The TestRole operation tests the IAM role used to create the pipeline.

The C<TestRole> action lets you determine whether the IAM role you are
using has sufficient permissions to let Elastic Transcoder perform
tasks associated with the transcoding process. The action attempts to
assume the specified IAM role, checks read access to the input and
output buckets, and tries to send a test notification to Amazon SNS
topics that you specify.











=head2 UpdatePipeline(Id => Str, [AwsKmsKeyArn => Str, ContentConfig => Paws::ElasticTranscoder::PipelineOutputConfig, InputBucket => Str, Name => Str, Notifications => Paws::ElasticTranscoder::Notifications, Role => Str, ThumbnailConfig => Paws::ElasticTranscoder::PipelineOutputConfig])

Each argument is described in detail in: L<Paws::ElasticTranscoder::UpdatePipeline>

Returns: a L<Paws::ElasticTranscoder::UpdatePipelineResponse> instance

  

Use the C<UpdatePipeline> operation to update settings for a pipeline.
When you change pipeline settings, your changes take effect
immediately. Jobs that you have already submitted and that Elastic
Transcoder has not started to process are affected in addition to jobs
that you submit after you change settings.











=head2 UpdatePipelineNotifications(Id => Str, Notifications => Paws::ElasticTranscoder::Notifications)

Each argument is described in detail in: L<Paws::ElasticTranscoder::UpdatePipelineNotifications>

Returns: a L<Paws::ElasticTranscoder::UpdatePipelineNotificationsResponse> instance

  

With the UpdatePipelineNotifications operation, you can update Amazon
Simple Notification Service (Amazon SNS) notifications for a pipeline.

When you update notifications for a pipeline, Elastic Transcoder
returns the values that you specified in the request.











=head2 UpdatePipelineStatus(Id => Str, Status => Str)

Each argument is described in detail in: L<Paws::ElasticTranscoder::UpdatePipelineStatus>

Returns: a L<Paws::ElasticTranscoder::UpdatePipelineStatusResponse> instance

  

The UpdatePipelineStatus operation pauses or reactivates a pipeline, so
that the pipeline stops or restarts the processing of jobs.

Changing the pipeline status is useful if you want to cancel one or
more jobs. You can't cancel jobs after Elastic Transcoder has started
processing them; if you pause the pipeline to which you submitted the
jobs, you have more time to get the job IDs for the jobs that you want
to cancel, and to send a CancelJob request.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

