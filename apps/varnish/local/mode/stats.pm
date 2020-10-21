#
# Copyright 2020 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package apps::varnish::local::mode::stats;

use base qw(centreon::plugins::templates::counter);
use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use JSON::XS;

sub configure_varnish_stats {
    my ($self, %options) = @_;

    $self->{varnish_stats} = [
        { entry => 'client_conn', nlabel => 'connections.client.accepted.persecond', display_ok => 1, per_second => 1 },
        { entry => 'client_drop', nlabel => 'connections.client.dropped.persecond', display_ok => 1, per_second => 1 },
        { entry => 'client_req', nlabel => 'connections.client.request.received.persecond', display_ok => 1, per_second => 1 },
        { entry => 'client_drop_late', nlabel => 'connections.client.dropped.late.persecond', display_ok => 0, per_second => 1 },
        { entry => 'client_req_400', nlabel => 'connections.client.request400.received.persecond', display_ok => 0, per_second => 1 },
        { entry => 'client_req_411', nlabel => 'connections.client.request411.received.persecond', display_ok => 0, per_second => 1 },
        { entry => 'client_req_413', nlabel => 'connections.client.request413.received.persecond', display_ok => 0, per_second => 1 },
        { entry => 'client_req_417', nlabel => 'connections.client.request417.received.persecond', display_ok => 0, per_second => 1 },

        { entry => 'backend_conn', nlabel => 'backends.connections.success.persecond', display_ok => 0, per_second => 1 },
        { entry => 'backend_unhealthy', nlabel => 'backends.connections.unhealthy.persecond', display_ok => 0, per_second => 1 },
        { entry => 'backend_busy', nlabel => 'backends.connections.busy.persecond', display_ok => 0, per_second => 1 },
        { entry => 'backend_fail', nlabel => 'backends.connections.fail.persecond', display_ok => 0, per_second => 1 },
        { entry => 'backend_reuse', nlabel => 'backends.connections.reuse.persecond', display_ok => 0, per_second => 1 },
        { entry => 'backend_recycle', nlabel => 'backends.connections.recycle.persecond', display_ok => 0, per_second => 1 },
        { entry => 'backend_retry', nlabel => 'backends.connections.retry.persecond', display_ok => 0, per_second => 1 },
        { entry => 'backend_req', nlabel => 'backends.requests.persecond', display_ok => 0, per_second => 1 },

        { entry => 'cache_hit', nlabel => 'cache.hit.persecond', display_ok => 0, per_second => 1 },
        { entry => 'cache_hitpass', nlabel => 'cache.hitpass.persecond', display_ok => 0, per_second => 1 },
        { entry => 'cache_miss', nlabel => 'cache.miss.persecond', display_ok => 0, per_second => 1 },
        
        { entry => 'n_sess_mem', nlabel => 'structure.session.memory.count', display_ok => 0 },
        { entry => 'n_sess', nlabel => 'structure.session.count', display_ok => 0 },
        { entry => 'n_sess', nlabel => 'structure.session.count', display_ok => 0 },
        { entry => 'n_object', nlabel => 'structure.object.count', display_ok => 0 },
        { entry => 'n_vampireobject', nlabel => 'object.unresurrected.count', display_ok => 0 },
        { entry => 'n_objectcore', nlabel => 'structure.objectcore.count', display_ok => 0 },
        { entry => 'n_objecthead', nlabel => 'structure.objecthead.count', display_ok => 0 },
        { entry => 'n_waitinglist', nlabel => 'structure.waitinglist.count', display_ok => 0 },
        { entry => 'n_vbc', nlabel => 'structure.vbc.count', display_ok => 0 },
        { entry => 'n_backend', nlabel => 'backend.count', display_ok => 0 },
        { entry => 'n_expired', nlabel => 'object.expired.count', display_ok => 0 },
        { entry => 'n_lru_nuked', nlabel => 'object.lru.nuked.count', display_ok => 0 },
        { entry => 'n_lru_moved', nlabel => 'object.lru.moved.count', display_ok => 0 },
        
        { entry => 'n_objsendfile', nlabel => 'object.sent.file.persecond', display_ok => 0, per_second => 1 },
        { entry => 'n_objwrite', nlabel => 'object.sent.write.persecond', display_ok => 0, per_second => 1 },
        { entry => 'n_objoverflow', nlabel => 'object.overflow.workspace.persecond', display_ok => 0, per_second => 1 },
        
        { entry => 'shm_records', nlabel => 'shm.records.persecond', display_ok => 0, per_second => 1 },
        { entry => 'shm_writes', nlabel => 'shm.writes.persecond', display_ok => 0, per_second => 1 },
        { entry => 'shm_flushes', nlabel => 'shm.flushes.persecond', display_ok => 0, per_second => 1 },
        { entry => 'shm_cont', nlabel => 'shm.contentions.persecond', display_ok => 0, per_second => 1 },
        { entry => 'shm_cycles', nlabel => 'shm.cycles.persecond', display_ok => 0, per_second => 1 },
        
        { entry => 'sms_nreq', nlabel => 'sms.allocator.requests.persecond', display_ok => 0, per_second => 1 },
        { entry => 'sms_nobj', nlabel => 'sms.outstanding.allocations.count', display_ok => 0 },
        { entry => 'sms_nbytes', nlabel => 'sms.outstanding.bytes', display_ok => 0, custom_output => $self->can('custom_output_scale_bytes') },
        { entry => 'sms_balloc', nlabel => 'sms.outstanding.allocated.bytes', display_ok => 0, custom_output => $self->can('custom_output_scale_bytes') },
        { entry => 'sms_bfree', nlabel => 'sms.outstanding.freed.bytes', display_ok => 0, custom_output => $self->can('custom_output_scale_bytes') },
        
        { entry => 'fetch_head', nlabel => 'fetch.head.persecond', display_ok => 0, per_second => 1 },
        { entry => 'fetch_length', nlabel => 'fetch.length.persecond', display_ok => 0, per_second => 1 },
        { entry => 'fetch_chunked', nlabel => 'fetch.chunked.persecond', display_ok => 0, per_second => 1 },
        { entry => 'fetch_eof', nlabel => 'fetch.eof.persecond', display_ok => 0, per_second => 1 },
        { entry => 'fetch_bad', nlabel => 'fetch.badheaders.persecond', display_ok => 0, per_second => 1 },
        { entry => 'fetch_close', nlabel => 'fetch.close.persecond', display_ok => 0, per_second => 1 },
        { entry => 'fetch_oldhttp', nlabel => 'fetch.oldhttp.persecond', display_ok => 0, per_second => 1 },
        { entry => 'fetch_zero', nlabel => 'fetch.zero.persecond', display_ok => 0, per_second => 1 },
        { entry => 'fetch_failed', nlabel => 'fetch.failed.persecond', display_ok => 0, per_second => 1 },
        { entry => 'fetch_1xx', nlabel => 'fetch.1xx.persecond', display_ok => 0, per_second => 1 },
        { entry => 'fetch_204', nlabel => 'fetch.204.persecond', display_ok => 0, per_second => 1 },
        { entry => 'fetch_304', nlabel => 'fetch.304.persecond', display_ok => 0, per_second => 1 },

        { entry => 'n_ban', nlabel => 'ban.total.active.count', display_ok => 0 },
        { entry => 'n_ban_add', nlabel => 'ban.new.added.persecond', display_ok => 0, per_second => 1 },
        { entry => 'n_ban_retire', nlabel => 'ban.old.deleted.persecond', display_ok => 0, per_second => 1 },
        { entry => 'n_ban_obj_test', nlabel => 'ban.object.tested.persecond', display_ok => 0, per_second => 1 },
        { entry => 'n_ban_re_test', nlabel => 'ban.object.tested.regexp.persecond', display_ok => 0, per_second => 1 },
        { entry => 'n_ban_dups', nlabel => 'ban.duplicate.removed.persecond', display_ok => 0, per_second => 1 },
        
        { entry => 'dir_dns_lookups', nlabel => 'dns.director.lookups.persecond', display_ok => 0, per_second => 1 },
        { entry => 'dir_dns_failed', nlabel => 'dns.director.lookups.failed.persecond', display_ok => 0, per_second => 1 },
        { entry => 'dir_dns_hit', nlabel => 'dns.director.lookups.cachehit.persecond', display_ok => 0, per_second => 1 },
        { entry => 'dir_dns_cache_full', nlabel => 'dns.director.cache.full.persecond', display_ok => 0, per_second => 1 },

        { entry => 'esi_errors', nlabel => 'esi.parse.errors.persecond', display_ok => 0, per_second => 1 },
        { entry => 'esi_warnings', nlabel => 'esi.parse.warnings.persecond', display_ok => 0, per_second => 1 },

        { entry => 'hcb_nolock', nlabel => 'hck.lookups.nolock.persecond', display_ok => 0, per_second => 1 },
        { entry => 'hcb_lock', nlabel => 'hck.lookups.lock.persecond', display_ok => 0, per_second => 1 },
        { entry => 'hcb_insert', nlabel => 'hck.inserts.persecond', display_ok => 0, per_second => 1 },

        { entry => 'n_vcl', nlabel => 'vlc.total.count', display_ok => 0, diff => 1 },
        { entry => 'n_vcl_avail', nlabel => 'vlc.available.count', display_ok => 0, diff => 1 },
        { entry => 'n_vcl_discard', nlabel => 'vlc.discarded.count', display_ok => 0, diff => 1 },

        { entry => 'sess_conn', nlabel => 'sessions.accepted.count', display_ok => 0, diff => 1 },
        { entry => 'sess_drop', nlabel => 'sessions.dropped.count', display_ok => 0, diff => 1 },
        { entry => 'sess_fail', nlabel => 'sessions.failed.count', display_ok => 0, diff => 1 },
        { entry => 'sess_pipe_overflow', nlabel => 'sessions.pipe.overflow.count', display_ok => 0, diff => 1 },
        { entry => 'sess_queued', nlabel => 'sessions.queued.count', display_ok => 0, diff => 1 },
        { entry => 'sess_readahead', nlabel => 'sessions.readahead.count', display_ok => 0, diff => 1 },
        { entry => 'sess_closed', nlabel => 'sessions.closed.count', display_ok => 0, diff => 1 },
        { entry => 'sess_herd', nlabel => 'sessions.herd.count', display_ok => 0, diff => 1 },
        { entry => 'sess_linger', nlabel => 'sessions.linger.count', display_ok => 0, diff => 1 },
        { entry => 'sess_closed', nlabel => 'sessions.closed.count', display_ok => 0, diff => 1 },
        { entry => 'sess_pipeline', nlabel => 'sessions.pipeline.count', display_ok => 0, diff => 1 },
        
        { entry => 'threads', nlabel => 'threads.total.count', display_ok => 0 },
        { entry => 'threads_created', nlabel => 'threads.created.count', display_ok => 0, diff => 1 },
        { entry => 'threads_limited', nlabel => 'threads.limited.count', display_ok => 0, diff => 1 },
        { entry => 'threads_destroyed', nlabel => 'threads.destroyed.count', display_ok => 0, diff => 1 },
        { entry => 'threads_failed', nlabel => 'threads.failed.count', display_ok => 0, diff => 1 },
        { entry => 'thread_queue_len', nlabel => 'threads.queue.length.count', display_ok => 0 },
        
        { entry => 's_sess', nlabel => 'total.sessions.seen.count', display_ok => 0, diff => 1 },
        { entry => 's_req', nlabel => 'total.requests.count', display_ok => 0, diff => 1 },
        { entry => 's_fetch', nlabel => 'total.backends.fetch.count', display_ok => 0, diff => 1 },

        { entry => 'n_wrk', nlabel => 'workers.threads.count', display_ok => 0 },
        { entry => 'n_wrk_create', nlabel => 'workers.threads.created.count', display_ok => 0, diff => 1 },
        { entry => 'n_wrk_failed', nlabel => 'workers.threads.failed.count', display_ok => 0, diff => 1 },
        { entry => 'n_wrk_max', nlabel => 'workers.threads.limited.count', display_ok => 0, diff => 1 },
        { entry => 'n_wrk_lqueue', nlabel => 'workers.requests.queue.length.count', display_ok => 0, diff => 1 },
        { entry => 'n_wrk_queued', nlabel => 'workers.requests.queued.count', display_ok => 0, diff => 1 },
        { entry => 'n_wrk_drop', nlabel => 'workers.requests.dropped.count', display_ok => 0, diff => 1 },

        { entry => 's0.g_space', category => 'SMA', nlabel => 'storage.space.free.bytes', display_ok => 0, custom_output => $self->can('custom_output_scale_bytes') },
    ];
}

sub custom_output_scale_bytes { 
    my ($self, %options) = @_;

    my $label = $self->{label};
    $label =~ s/-/_/g;
    my ($value, $unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{$label }); 
    return sprintf('%s: %.2f %s', $self->{result_values}->{$label . '_description'},  $value, $unit);
}

sub custom_output_second { 
    my ($self, %options) = @_;

    my $label = $self->{label};
    $label =~ s/-/_/g;
    my $msg = sprintf('%s: %.2f/s', $self->{result_values}->{$label . '_description'},  $self->{result_values}->{$label});
    return $msg;
}

sub custom_output { 
    my ($self, %options) = @_;

    my $label = $self->{label};
    $label =~ s/-/_/g;
    my $msg = sprintf('%s: %s', $self->{result_values}->{$label . '_description'},  $self->{result_values}->{$label });
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->configure_varnish_stats();

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [];
    foreach (@{$self->{varnish_stats}}) {
        my $label = $_->{entry};
        $label =~ s/_/-/g;
        push @{$self->{maps_counters}->{global}},
            { label => $label, nlabel => $_->{nlabel}, display_ok => $_->{display_ok}, set => {
                    key_values => [ { name => $_->{entry}, diff => $_->{diff}, per_second => $_->{per_second} }, { name => $_->{entry}. '_description' } ],
                    closure_custom_output => defined($_->{custom_output}) ? $_->{custom_output} :
                        (defined($_->{per_second}) ? $self->can('custom_output_second') : $self->can('custom_output')),
                    perfdatas => [
                        { label => $_->{entry}, 
                          template => defined($_->{per_second}) ? '%.2f' : '%s',
                          min => 0 }
                    ]
                }
            }
        ;
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_varnish_old {
    my ($self, %options) = @_;

    return if (!defined($options{json}->{uptime}));
    #   "cache_hit": {"value": 56320, "flag": "a", "description": "Cache hits"},
    #   "cache_hitpass": {"value": 0, "flag": "a", "description": "Cache hits for pass"},
    #   "SMA.s0.g_space": {"type": "SMA", "ident": "s0", "value": 2147483648, "flag": "i", "description": "Bytes available"},
    foreach (@{$self->{varnish_stats}}) {
        my $entry = defined($_->{category}) ? $_->{category} . '.' . $_->{entry} : $_->{entry};
        next if (!defined($options{json}->{$entry}));
        $self->{global}->{$_->{entry}} = $options{json}->{$entry}->{value};
        $self->{global}->{$_->{entry} . '_description'} = $options{json}->{$entry}->{description};
    }
}

sub check_varnish_new {
    my ($self, %options) = @_;

    return if (!defined($options{json}->{'MAIN.uptime'}));

    #   "MAIN.cache_hit": {"type": "MAIN", "value": 18437, "flag": "a", "description": "Cache hits"},
    #   "MAIN.cache_hitpass": {"type": "MAIN", "value": 3488, "flag": "a", "description": "Cache hits for pass"},
    #   "MAIN.cache_miss": {"type": "MAIN", "value": 5782, "flag": "a", "description": "Cache misses"},
    #   "SMA.s0.g_space": { "description": "Bytes available", "flag": "g", "format": "B", "value": 4244053932 },
    foreach (@{$self->{varnish_stats}}) {
        my $category = defined($_->{category}) ? $_->{category} : 'MAIN';
        next if (!defined($options{json}->{$category . '.' . $_->{entry}}));
        $self->{global}->{$_->{entry}} = $options{json}->{$category . '.' . $_->{entry}}->{value};
        $self->{global}->{$_->{entry} . '_description'} = $options{json}->{$category . '.' . $_->{entry}}->{description};
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'varnishstat',
        command_path => '/usr/bin',
        command_options => '-1 -j 2>&1'
    );

    $self->{global} = {};

    my $content;
    eval {
        $content = JSON::XS->new->utf8->decode($stdout);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    $self->check_varnish_old(json => $content);
    $self->check_varnish_new(json => $content);

    $self->{cache_name} = 'cache_varnish_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{hostname}) ? md5_hex($self->{option_results}->{hostname}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
};


1;

__END__

=head1 MODE

Check statistics with varnishstat command.

Command used: /usr/bin/varnishstat -1 -j 2>&1

=over 8

=item B<--warning-[countername]> B<--critical-[countername]>

Thresholds. Use option --list-counters to see available counters

=back

=cut
