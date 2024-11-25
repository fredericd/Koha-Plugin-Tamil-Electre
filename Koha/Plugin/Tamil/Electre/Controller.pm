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
        $logger->debug('Examen du cache');
        for my $isbn_raw (keys %isbn) {
            if (my $notice = $cache->get_from_cache("tamelec-$isbn_raw")) {
                $logger->debug("Trouvé dans le cache: $isbn_raw");
                $isbn{$isbn_raw} = $notice;
            }
        }
    }

    # Y a-t-il des ean qui étaient absents du cache ?
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
            my $notice = { notfound => 1 };
            $isbn{$isbn_raw} = $notice;
            if ($use_cache) {
                $logger->debug("EAN invalide mis en cache: $isbn_raw");
                $cache->set_in_cache("tamelec-$isbn_raw", $notice, { expiry => $expiry });
            }
        }
    }

    # Y a-t-il des ean à rechercher chez Electre ?
    if (my @eans = keys %ean_to_isbn) {
        $logger->debug('Recherche dans Electre des EAN: ' . join(',', @eans));

        # Appel webservice Electre
        my $notice = { electre => {}, koha => {} };

	    my $token_key = 'tamelec-token';
        my $token = $cache->get_from_cache($token_key);
		if ($token) {
			$logger->debug('Token Electre trouvé dans le cache');
		}
		else {
			my $tx = $ua->post($pc->{api}->{login}->{url} => form => {
				grant_type => 'password',
				client_id  => 'api-client',
				username   => $pc->{api}->{login}->{user},
				password   => $pc->{api}->{login}->{password},
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
                            my $tt = Template->new();
                            my $template = $pc->{opac}->{detail}->{infos}->{template};
                            my $html = '';
                            $tt->process(\$template, { electre => $not, conf => $pc }, \$html)
                                or $html = "Mauvais template : " . $template->error();
                            my $notice = {
                                electre => $not,
                                koha => { opac => { info => $html } },
                            };
                            $isbn{$id} = $notice;
                            if ($use_cache) {
                                $cache->set_in_cache("tamelec-$id", $notice, { expiry => $expiry });
                            }
                            last;
                        }
                    }
                }
            }
        }
        else {
            # Impossible d'obtenir un token
            # Pb user/password ?
            $logger->warning("Impossible d'obtenir un token pour les services web Electre");
        }
    }

    # Les derniers ISBN non trouvés
    for my $id (keys %isbn) {
        next if $isbn{$id};
        my $notice = { notfound => 1 };
        $isbn{$id} = $notice;
        $cache->set_in_cache("tamelec-$id", $notice, { expiry => $expiry })
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
