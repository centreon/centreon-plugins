#
# Copyright 2026 Centreon (http://www.centreon.com/)
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
# Authors : Valentin MAROT <contact@valentin-marot.fr>
#

#
# Mode custom : dialogue avec l'API REST Storage Virtualize.
#
# Trois particularites de cette API dictent la conception :
#   1. Toutes les commandes sont des POST, y compris les lectures 'ls*'.
#   2. Le prefixe est /rest/v1 depuis la 8.1.3, /rest avant : on detecte.
#   3. Une session dure 2 h actives ou 30 min d'inactivite, puis renvoie 403.
#      Le jeton est donc mis en cache sur le collecteur et reobtenu a la volee
#      quand la baie le refuse.
#

package storage::ibm::flashsystem::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON::XS;
use Digest::MD5 qw(md5_hex);

sub new {
    my ($class, %options) = @_;
    my $self = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }

    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s'       => { name => 'hostname' },
            'port:s'           => { name => 'port' },
            'proto:s'          => { name => 'proto' },
            'api-username:s'   => { name => 'api_username' },
            'api-password:s'   => { name => 'api_password' },
            'api-path:s'       => { name => 'api_path' },
            'timeout:s'        => { name => 'timeout' },
            'token-lifetime:s' => { name => 'token_lifetime' },
            'command-cache-ttl:s' => { name => 'command_cache_ttl' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{cache} = centreon::plugins::statefile->new(%options);
    $self->{response_cache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname}       = $self->{option_results}->{hostname};
    $self->{port}           = defined($self->{option_results}->{port}) && $self->{option_results}->{port} ne '' ? $self->{option_results}->{port} : 7443;
    $self->{proto}          = defined($self->{option_results}->{proto}) && $self->{option_results}->{proto} ne '' ? $self->{option_results}->{proto} : 'https';
    $self->{timeout}        = defined($self->{option_results}->{timeout}) && $self->{option_results}->{timeout} =~ /^\d+$/ ? $self->{option_results}->{timeout} : 30;
    $self->{api_username}   = $self->{option_results}->{api_username};
    $self->{api_password}   = $self->{option_results}->{api_password};
    $self->{api_path}       = $self->{option_results}->{api_path};
    # Duree de reutilisation du jeton. On la veut LONGUE : la baie limite le
    # nombre d'authentifications et renvoie 429 quand on insiste, alors qu'un
    # jeton perime se rattrape tout seul par le reessai sur 401/403. Expirer le
    # jeton par precaution ne protege de rien et coute une authentification.
    # 6600 s reste sous la limite de 2 h de session active.
    $self->{token_lifetime} = defined($self->{option_results}->{token_lifetime}) && $self->{option_results}->{token_lifetime} =~ /^\d+$/ ? $self->{option_results}->{token_lifetime} : 6600;
    # Duree de reutilisation d'une reponse de commande. 55 s par defaut :
    # assez pour absorber la rafale des controles qui partent dans la meme
    # minute, court devant la cadence de 5 min — le retard maximal d'une
    # detection reste sous une minute. 0 desactive le cache.
    $self->{command_cache_ttl} = defined($self->{option_results}->{command_cache_ttl}) && $self->{option_results}->{command_cache_ttl} =~ /^\d+$/ ? $self->{option_results}->{command_cache_ttl} : 55;

    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --hostname option.');
        $self->{output}->option_exit();
    }
    if (!defined($self->{api_username}) || $self->{api_username} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-username option.');
        $self->{output}->option_exit();
    }
    if (!defined($self->{api_password}) || $self->{api_password} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --api-password option.');
        $self->{output}->option_exit();
    }

    $self->{cache}->check_options(option_results => $self->{option_results});
    $self->{response_cache}->check_options(option_results => $self->{option_results});

    return 0;
}

sub get_connection_info {
    my ($self, %options) = @_;

    return $self->{hostname} . ':' . $self->{port};
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{port}     = $self->{port};
    $self->{option_results}->{proto}    = $self->{proto};
    $self->{option_results}->{timeout}  = $self->{timeout};
}

sub settings {
    my ($self, %options) = @_;

    return if (defined($self->{settings_done}));
    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
    $self->{settings_done} = 1;
}

# Les prefixes a essayer, dans l'ordre. --api-path fige le choix quand on veut
# eviter la detection (une baie de plus dans le parc, un firmware connu).
sub api_paths {
    my ($self, %options) = @_;

    return ($self->{api_path}) if (defined($self->{api_path}) && $self->{api_path} ne '');
    return ('/rest/v1', '/rest');
}

sub decode_response {
    my ($self, %options) = @_;

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($options{content});
    };
    if ($@) {
        return undef;
    }
    return $decoded;
}

# Authentification : POST <prefixe>/auth avec les identifiants en en-tetes.
# La reponse porte un jeton (JWT sur les firmwares recents, chaine hexadecimale
# avant). En cas d'echec, le corps porte le code IBM (CMMVCxxxxE) : on le
# remonte tel quel, c'est lui qui distingue un mot de passe faux d'un compte
# sans role.
sub authenticate {
    my ($self, %options) = @_;

    $self->settings();

    my $last_message;

    # La baie limite le rythme des authentifications et repond 429. Plusieurs
    # controles qui expirent en meme temps suffisent a le declencher, d'ou une
    # temporisation croissante avant d'abandonner. Le total reste sous le
    # timeout d'un controle Centreon.
    foreach my $attempt (1 .. 3) {
        my $throttled = 0;

        foreach my $path ($self->api_paths()) {
            my $content = $self->{http}->request(
                method => 'POST',
                url_path => $path . '/auth',
                header => [
                    'X-Auth-Username: ' . $self->{api_username},
                    'X-Auth-Password: ' . $self->{api_password},
                    'Accept: application/json'
                ],
                unknown_status => '',
                warning_status => '',
                critical_status => ''
            );

            my $code = $self->{http}->get_code();
            if ($code == 200) {
                my $decoded = $self->decode_response(content => $content);
                if (defined($decoded) && defined($decoded->{token}) && $decoded->{token} ne '') {
                    return ($decoded->{token}, $path);
                }
            }

            $last_message = 'HTTP ' . $code . (defined($content) && $content ne '' ? ' - ' . $content : '');

            # Inutile d'essayer l'autre prefixe : c'est le rythme qui est
            # refuse, pas l'URL.
            if ($code == 429) {
                $throttled = 1;
                last;
            }
        }

        last if (!$throttled || $attempt == 3);
        sleep($attempt * 2);
    }

    # Sur 429 on ne sort pas : l'appelant va relire le cache, qu'un controle
    # voisin a peut-etre rafraichi pendant qu'on patientait.
    return (undef, undef, $last_message) if (defined($last_message) && $last_message =~ /^HTTP 429/);

    $self->{output}->add_option_msg(
        short_msg => 'Authentication failed: ' . (defined($last_message) ? $last_message : 'no response')
    );
    $self->{output}->option_exit();
}

# Nom du fichier de cache : une entree par baie et par compte, partagee par
# tous les controles de cette baie.
sub statefile_name {
    my ($self, %options) = @_;

    return 'ibm_flashsystem_api_'
        . md5_hex($self->{hostname} . ':' . $self->{port})
        . '_' . md5_hex($self->{api_username});
}

# Relit le cache et rend le jeton s'il est encore valide, sinon undef.
sub cached_token {
    my ($self, %options) = @_;

    return undef if ($self->{cache}->read(statefile => $self->statefile_name()) == 0);

    my $token = $self->{cache}->get(name => 'token');
    my $path = $self->{cache}->get(name => 'api_path');
    my $expires_on = $self->{cache}->get(name => 'expires_on');

    return undef if (!defined($token) || !defined($path) || !defined($expires_on));
    return undef if (time() >= $expires_on);

    $self->{token} = $token;
    $self->{resolved_path} = $path;
    return $token;
}

# Le jeton est partage par tous les controles d'une meme baie et d'un meme
# compte : sans ce cache, chaque service ouvrirait sa propre session.
sub get_token {
    my ($self, %options) = @_;

    my $force = defined($options{force}) && $options{force} == 1;

    # Le jeton qu'on ne veut surtout pas reprendre : celui que la baie vient de
    # refuser, quand on est ici a cause d'un 401/403.
    my $rejected = $force ? $self->{token} : undef;

    # cached_token() lit le fichier, ce qui fixe aussi son nom pour l'ecriture.
    my $cached = $self->cached_token();
    return $cached if (!$force && defined($cached));

    my ($token, $path, $throttle_message) = $self->authenticate();

    # Authentification refusee pour cause de rythme. Tous les controles d'une
    # meme baie constatent l'expiration du jeton au meme moment et se ruent sur
    # /auth : le temps qu'on ait patiente, l'un d'eux a souvent reussi et ecrit
    # le cache. On le relit plutot que d'insister — sauf s'il rend le jeton
    # qu'on vient justement de faire rejeter.
    if (!defined($token)) {
        my $refreshed = $self->cached_token();
        if (defined($refreshed) && (!defined($rejected) || $refreshed ne $rejected)) {
            return $refreshed;
        }

        $self->{output}->add_option_msg(
            short_msg => 'Authentication failed: ' . $throttle_message
                . ' The array is rate-limiting authentications and no other check has'
                . ' refreshed the cached token. Raising --token-lifetime spaces these out.'
        );
        $self->{output}->option_exit();
    }

    $self->{cache}->write(data => {
        token => $token,
        api_path => $path,
        expires_on => time() + $self->{token_lifetime}
    });
    $self->{token} = $token;
    $self->{resolved_path} = $path;
    return $token;
}

# request : execute une commande CLI via l'API.
#
# $options{command}  nom de la commande, par exemple 'lsvdisk'
# $options{payload}  parametres, par exemple { filtervalue => 'fixed=no' }
#
# Renvoie toujours une reference de tableau : l'API rend tantot un objet seul
# (lssystem), tantot un tableau. Les modes n'ont donc jamais a tester la forme.
# Cache de REPONSES, partage entre les controles d'une meme baie via le
# repertoire d'etat du collecteur — le meme principe que le cache de jeton.
#
# Pourquoi : le decoupage en services multiplie les executions du plugin, et
# plusieurs services relisent les MEMES commandes dans la meme minute — trois
# services issus du mode performance relisent chacun lssystemstats, les deux
# services de replication refont les quatre memes appels, et lssystem est lu
# par la moitie des modes. La baie limite le rythme et repond 429. Le premier
# controle du cycle remplit le cache, les suivants le relisent : la rafale
# disparait sans changer la cadence de supervision. Toutes les commandes sont
# des lectures ls*, la mise en cache est donc semantiquement sure.

sub response_cache_name {
    my ($self, %options) = @_;

    return 'ibm_flashsystem_api_rsp_' . md5_hex($self->{hostname} . ':' . $self->{port})
        . '_' . md5_hex($self->{api_username} . '|' . $options{key});
}

sub cached_response {
    my ($self, %options) = @_;

    return undef if ($self->{response_cache}->read(statefile => $self->response_cache_name(key => $options{key})) == 0);

    my $stamp = $self->{response_cache}->get(name => 'stamp');
    my $response = $self->{response_cache}->get(name => 'response');
    return undef if (!defined($stamp) || $stamp !~ /^\d+$/ || ref($response) ne 'ARRAY');
    return undef if (time() - $stamp > $options{max_age});
    return $response;
}

sub store_response {
    my ($self, %options) = @_;

    # read() d'abord : c'est lui qui fixe le nom du fichier que write() utilise.
    $self->{response_cache}->read(statefile => $self->response_cache_name(key => $options{key}));
    $self->{response_cache}->write(data => { stamp => time(), response => $options{response} });
}

sub request {
    my ($self, %options) = @_;

    my $payload = defined($options{payload}) ? $options{payload} : {};
    # canonical : le meme payload donne toujours la meme cle, quel que soit
    # l'ordre interne du hachage.
    my $cache_key = $options{command} . '|' . JSON::XS->new->utf8->canonical->encode($payload);

    if ($self->{command_cache_ttl} > 0) {
        my $cached = $self->cached_response(key => $cache_key, max_age => $self->{command_cache_ttl});
        return $cached if (defined($cached));
    }

    my $token = $self->get_token();

    my $attempt = 0;
    while (1) {
        $attempt++;
        $self->settings();

        my $content = $self->{http}->request(
            method => 'POST',
            url_path => $self->{resolved_path} . '/' . $options{command},
            header => [
                'X-Auth-Token: ' . $token,
                'Content-Type: application/json',
                'Accept: application/json'
            ],
            query_form_post => JSON::XS->new->utf8->encode($payload),
            unknown_status => '',
            warning_status => '',
            critical_status => ''
        );

        my $code = $self->{http}->get_code();

        # 401 / 403 : session expiree ou invalidee cote baie. On se
        # reauthentifie une fois, puis on abandonne pour ne pas boucler.
        # C'est ce rattrapage qui permet de garder un jeton longtemps en cache
        # plutot que de le renouveler par precaution.
        if (($code == 401 || $code == 403) && $attempt == 1) {
            $token = $self->get_token(force => 1);
            next;
        }

        # 429 sur une commande : la baie limite le rythme des requetes. On
        # temporise en allongeant le pas avant d'abandonner.
        if ($code == 429 && $attempt <= 3) {
            sleep($attempt * 3);
            next;
        }

        # Rafale persistante malgre les reessais : plutot que de rendre le
        # controle UNKNOWN, on sert la derniere reponse connue si elle a moins
        # d'un quart d'heure. Un etat legerement date vaut mieux qu'un trou
        # dans la supervision pendant une saturation passagere de l'API.
        if ($code == 429 && $self->{command_cache_ttl} > 0) {
            my $stale = $self->cached_response(key => $cache_key, max_age => 900);
            if (defined($stale)) {
                $self->{output}->output_add(
                    long_msg => "HTTP 429 on '" . $options{command} . "': served the cached response instead."
                );
                return $stale;
            }
        }

        if ($code != 200) {
            $self->{output}->add_option_msg(
                short_msg => "API command '" . $options{command} . "' failed (HTTP " . $code . ")"
                    . (defined($content) && $content ne '' ? ': ' . $content : '')
            );
            $self->{output}->option_exit();
        }

        my $decoded = $self->decode_response(content => $content);
        if (!defined($decoded)) {
            $self->{output}->add_option_msg(short_msg => "Cannot decode API response for command '" . $options{command} . "'");
            $self->{output}->option_exit();
        }

        my $result = ref($decoded) eq 'ARRAY' ? $decoded : [ $decoded ];
        $self->store_response(key => $cache_key, response => $result)
            if ($self->{command_cache_ttl} > 0);
        return $result;
    }
}

# Certaines commandes n'existent pas sur tous les firmwares ni sur tous les
# modeles : lspartition n'apparait qu'en 8.7, lsrcrelationship disparait des
# configurations qui n'utilisent que la replication par politique. Un mode
# generique doit pouvoir demander sans savoir, d'ou cette variante tolerante
# qui rend une liste vide plutot que de faire echouer le controle.
# L'API rend les capacites sous forme de chaines unitaires : "310.99TB",
# "0.00MB", parfois "1.25PB". Les seuils et la perfdata veulent des octets.
# Rend undef quand la valeur est absente ou non exploitable, pour qu'un mode
# puisse distinguer "zero" de "pas d'information".
sub size_to_bytes {
    my ($self, %options) = @_;

    my $value = $options{value};
    return undef if (!defined($value) || $value eq '');
    return undef if ($value !~ /^\s*([0-9]+(?:\.[0-9]+)?)\s*([KMGTPE]?)B?\s*$/i);

    my ($number, $unit) = ($1, uc($2));
    my %factor = ('' => 1, K => 1024, M => 1024**2, G => 1024**3,
                  T => 1024**4, P => 1024**5, E => 1024**6);

    return $number * $factor{$unit};
}

# Joignabilite de la baie, pour le seul usage du controle d'hote.
#
# On ne peut pas se contenter de "l'API a repondu ou non" : un jeton refuse, un
# 429 ou un certificat casse sont des problemes de supervision, pas des baies
# mortes. Les confondre ferait passer l'hote DOWN et rendrait TOUS ses services
# UNREACHABLE — on perdrait la supervision au moment ou elle sert le plus.
#
# Rend l'une de ces trois valeurs :
#   'unreachable' l'equipement ne repond pas du tout ;
#   'degraded'    il repond mais l'API refuse de nous servir ;
#   'ok'          l'API repond normalement.
sub reachability {
    my ($self, %options) = @_;

    $self->settings();

    my $content = $self->{http}->request(
        method => 'POST',
        url_path => ($self->api_paths())[0] . '/auth',
        header => [
            'X-Auth-Username: ' . $self->{api_username},
            'X-Auth-Password: ' . $self->{api_password},
            'Accept: application/json'
        ],
        unknown_status => '',
        warning_status => '',
        critical_status => ''
    );

    my $code = $self->{http}->get_code();
    return ('ok', 'API responded') if ($code == 200);

    # La bibliotheque HTTP rend un 500 synthetique quand la connexion elle-meme
    # a echoue : c'est le texte qui distingue "personne au bout du fil" d'une
    # reponse applicative.
    my $text = defined($content) ? $content : '';
    return ('unreachable', $text)
        if ($text =~ /can'?t connect|connection refused|no route to host|timeout|timed out/i);

    return ('degraded', 'HTTP ' . $code . ($text ne '' ? ' - ' . $text : ''));
}

sub request_optional {
    my ($self, %options) = @_;

    my $result;
    eval {
        local $SIG{__DIE__};
        $result = $self->request(%options);
    };
    return [] if ($@ || !defined($result));
    return $result;
}

1;

__END__

=head1 NAME

IBM Storage Virtualize REST API

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Management IP address or hostname of the system.

=item B<--port>

API port (default: 7443).

=item B<--proto>

Protocol (default: https).

=item B<--api-username>

Array account used to authenticate. The B<Monitor> role is sufficient and
recommended: it grants read-only access to the information commands.

=item B<--api-password>

Password of that account. Storage Virtualize has no API key: the credentials
are exchanged for a session token.

=item B<--api-path>

Pin the API prefix instead of detecting it. Storage Virtualize 8.1.3 and later
serve C</rest/v1>; earlier releases serve C</rest>. Left empty, both are tried
in that order.

=item B<--token-lifetime>

Seconds a cached session token is reused (default: 6600, just under the array's
two-hour cap on an active session).

Keep it long. The array rate-limits authentications and answers B<429 Too Many
Requests> when pressed, whereas an expired token costs nothing: the plugin
re-authenticates by itself when a command comes back 401 or 403. Expiring the
token early protects against nothing and spends an authentication.

=item B<--command-cache-ttl>

Seconds a command B<response> is reused across checks of the same array
(default: 55; 0 disables).

The array also rate-limits commands. Splitting the monitoring into
single-purpose services multiplies plugin runs that read the B<same> C<ls*>
commands within the same minute — the first check of the cycle fills the
cache, the others read it, and the burst disappears without changing the
check cadence. Every command is a read, so caching is semantically safe; the
worst case is a detection delayed by under a minute on a five-minute cadence.
When a command still gets a 429 after the retries, the last response is served
if it is less than fifteen minutes old, rather than turning the check UNKNOWN.

The token is cached per array and per account, so every check of the same
system shares it. If authentications look far too frequent, check that the
cache directory (C<--statefile-dir>, C</var/lib/centreon/centplugins> by
default) is writable by the account running the checks.

=item B<--timeout>

HTTP timeout in seconds (default: 30).

=back

=cut
