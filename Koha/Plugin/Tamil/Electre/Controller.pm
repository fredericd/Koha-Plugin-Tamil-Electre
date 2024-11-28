package Koha::Plugin::Tamil::Electre::Controller;

use Modern::Perl;
use utf8;
use Koha::Plugin::Tamil::Electre;
use Mojo::Base 'Mojolicious::Controller';
use Business::ISBN;
use YAML;

sub notices {
    my $c = shift->openapi->valid_input or return;

    my $plugin = Koha::Plugin::Tamil::Electre->new;
    my $pc     = $plugin->config();
    my $logger = $plugin->{logger};
    my %isbn   = map { $_ => undef } split /,/, $c->validation->param('isbn');
    my $cache  = $plugin->{cache};

    $logger->debug("Controller notices");
    my $ua = Mojo::UserAgent->new;
    $ua = $ua->connect_timeout($pc->{api}->{timeout});

    my $use_cache = $pc->{cache}->{enabled};
    my $expiry = $pc->{cache}->{expiry};
    if ($use_cache) {
        # On cherche les infos pour chaque ean
        $logger->debug('Recherche des EAN dans le cache');
        for my $isbn_raw (keys %isbn) {
            if (my $notice = $cache->get_from_cache("tamelec-$isbn_raw")) {
                $logger->debug("Trouvé dans le cache: $isbn_raw");
                $isbn{$isbn_raw} = $notice;
            }
        }
    }

    # Y a-t-il des ean qui étaient absents du cache ?
    my $notice_notfound = { notfound => 1 };
    my %ean_to_isbn;
    my @isbn_tosearch = grep { ! $isbn{$_} } keys %isbn;
    $logger->debug("EAN absents du cache: " . join(',', @isbn_tosearch))
        if @isbn_tosearch;
    for my $isbn_raw (@isbn_tosearch) {
        my $isbn = $isbn_raw ? Business::ISBN->new($isbn_raw) : undef;
        $isbn->fix_checksum if $isbn;
        my $ean;
        if ($isbn && $isbn->is_valid) {
            $ean = $isbn->as_isbn13;
            $ean = $ean->as_string;
            $ean =~ s/-//g;
        }
        if ($ean) {
            $ean_to_isbn{$ean} = $isbn_raw;
        }
        else {
            $isbn{$isbn_raw} = $notice_notfound;
            if ($use_cache) {
                $logger->debug("EAN invalide mis en cache: $isbn_raw");
                $cache->set_in_cache("tamelec-$isbn_raw", $notice_notfound, { expiry => $expiry });
            }
        }
    }

    # Y a-t-il des ean à rechercher chez Electre ?
    if (my @eans = keys %ean_to_isbn) {
        # Appel webservice Electre
        $logger->debug('Recherche dans Electre des EAN: ' . join(',', @eans));
        my $notice = { electre => {}, koha => {} };
        my $token_key = 'tamelec-token';
        my $token = $cache->get_from_cache($token_key);
        if ($token) {
            $logger->debug('Token Electre trouvé dans le cache');
        }
        else {
            my $login = $pc->{api}->{login};
            my $tx = $ua->post($login->{url} => form => {
                grant_type => 'password',
                client_id  => 'api-client',
                username   => $login->{user},
                password   => $login->{password},
            });
            my $res = $tx->res->json;
            $token = $res->{token_type} . ' ' . $res->{access_token};
            my $expiry = $res->{expires_in} - 10;
            $logger->debug("Token Electre obtenu et mis en cache pour $expiry");
            $cache->set_in_cache($token_key, $token, { expiry => $expiry });
        }
        if ($token) {
            my $url = $pc->{api}->{url} . '/notices/eans?' . join('&', map { "ean=$_" } @eans);
            $logger->debug("Appel Electre: $url");
            $ua->on(start => sub {
                my ($ua, $tx) = @_;
                $tx->req->headers->authorization($token);
            });
            my $tx = $ua->get($url);

            my $notices = $tx->result->json;
            if ($notices->{notices}) {
                # On a quelque chose
                $notices = $notices->{notices};
                for my $not (@$notices) {
                    for my $isbn (@{$not->{isbns}}) {
                        $isbn =~ s/-//g;
                        if (my $id = $ean_to_isbn{$isbn}) {
                            $logger->debug("Résultat, trouvé isbn $id / ean $isbn");
                            my $html = '';
                            my @info_fields = (
                                'biographie', 'quatriemeDeCouverture', 'tableDesMatieres',
                                'passagesMedia', 'bandesAnnonces', 'extrait',
                            );
                            if (grep { ! $not->{$_} == undef } @info_fields) {
                                my $tt = Template->new();
                                my $template = $pc->{opac}->{detail}->{infos}->{template};
                                $tt->process(\$template, { electre => $not, conf => $pc }, \$html)
                                    or $html = "Mauvais template : " . $tt->error();
                            }
                            my $notice = {
                                electre => $not,
                                koha => { opac => { info => $html } },
                            };
                            $isbn{$id} = $notice;
                            $cache->set_in_cache("tamelec-$id", $notice, { expiry => $expiry })
                                if $use_cache;
                            last;
                        }
                    }
                }
            }
        }
        else {
            # Impossible d'obtenir un token. Pb user/password ?
            $logger->warning("Impossible d'obtenir un token pour les services web Electre");
        }
    }

    # Les derniers ISBN non trouvés
    for my $id (keys %isbn) {
        next if $isbn{$id};
        $isbn{$id} = $notice_notfound;
        $cache->set_in_cache("tamelec-$id", $notice_notfound, { expiry => $expiry })
    }

    $c->render(
        status  => 200,
        openapi => {
            status => 'ok',
            reason => '',
            errors => [],
        },
        json => \%isbn,
    );
}

1;
