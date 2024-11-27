package Koha::Plugin::Tamil::Electre;

use Modern::Perl;
use utf8;
use base qw(Koha::Plugins::Base);
use CGI qw(-utf8);
use Koha::Cache;
use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);
use Encode qw/ decode /;
use JSON qw/ to_json /;
use Pithub::Markdown;


our $metadata = {
    name            => 'Tamil Electre',
    description     => 'Intégration Electre à Koha',
    author          => 'Tamil s.a.r.l.',
    date_authored   => '2024-11-25',
    date_updated    => "2024-11-25",
    minimum_version => '24.05.00.000',
    maximum_version => undef,
    copyright       => '2024',
    version         => '1.0.1',
};


my $DEFAULT_OPAC_TEMPLATE = <<EOS;
<style>
  #electre-infos {
    border: 1px solid;
    padding: 10px;
  }
  #electre-branding {
    text-align: right;
  }
  #electre-infos h1 {
    font-transform: uppercase;
    font-size: 120%;
    color: #727272;
  }
</style>
<div id="electre-infos">
  <div id="electre-branding">
    <img src="https://www.electre.com/img/login/logo-electre.svg" style="max-width: 130px;" />
  </div>
  [% IF electre.biographie %]
    <div id="electre-biographie">
      <h1>Biographie</h1>
      <div>[% electre.biographie %]</div>
    </div>
  [% END %]
  [% IF electre.quatriemeDeCouverture %]
    <div id="electre-quatriemeDeCouverture">
      <h1>Quatrième de couverture</h1>
      <div>[% electre.quatriemeDeCouverture %]</div>
    </div>
  [% END %]
  [% IF electre.extrait %]
    <div id="electre-extrait">
      <h1>Extrait fourni par l'éditeur</h1>
      <div>
        <a href="[% electre.extrait.extraitUrl %]">Télécharger [% electre.extrait.extraitFormat %]</a>
      </div>
    </div>
  [% END %]
  [% IF electre.tableDesMatieres %]
    <div id="electre-tableDesMatieres">
      <h1>Table des matières</h1>
      <div>[% electre.tableDesMatieres %]</div>
    </div>
  [% END %]
  [% IF electre.passagesMedia %]
    <div id="electre-passagesMedia">
      <h1>Passages Média</h1>
      <div>[% electre.passagesMedia %]</div>
    </div>
  [% END %]
  [% IF electre.bandesAnnonces %]
    <div id="electre-bandesAnnonces">
      <h1>Bandes annonces</h1>
      <div>[% electre.bandesAnnonces %]</div>
    </div>
  [% END %]
</div>
EOS


sub new {
    my ($class, $args) = @_;

    $args->{metadata} = $metadata;
    $args->{metadata}->{class} = $class;
    $args->{cache} = Koha::Cache->new();
    $args->{logger} = Koha::Logger->get({ interface => 'api' });

    $class->SUPER::new($args);
}


sub config {
    my $self = shift;

    my $c = $self->{args}->{c};
    unless ($c) {
        $c = $self->retrieve_data('c');
        if ($c) {
            utf8::encode($c);
            $c = decode_json($c);
        }
        else {
            $c = {};
        }
    }
    $c->{api}->{url} ||= 'https://api.electre-ng.com';
    $c->{api}->{timeout} ||= 60;
    $c->{api}->{login}->{url} = 'https://login.electre-ng.com/auth/realms/electre/protocol/openid-connect/token';
    $c->{cache}->{expiry} ||= 86400;
    $c->{opac}->{detail}->{cover}->{image} ||= 'imageCouverture';
    $c->{opac}->{detail}->{infos}->{template} ||= $DEFAULT_OPAC_TEMPLATE;
    $c->{opac}->{result}->{cover}->{image} ||= 'imagetteCouverture';

    $c->{metadata} = $self->{metadata};

    $self->{args}->{c} = $c;

    return $c;
}


sub get_form_config {
    my $cgi = shift;
    my $c = {
        api => {
            url => undef,
            timeout => undef,
            login => {
                url => undef,
                user => undef,
                password => undef,
            },
        },
        cache => {
            enabled => undef,
            expiry => undef,
        },
        opac => {
            detail => {
                enabled => undef,
                cover => {
                    enabled => undef,
                    image => undef,
                    maxwidth => undef,
                },
                infos => {
                    enabled => undef,
                    template => undef,
                }
            },
            result => {
                enabled => undef,
                cover => {
                    enabled => undef,
                    image => undef,
                    maxwidth => undef,
                },
            },
        },
    };

    my $set;
    $set = sub {
        my ($node, $path) = @_;
        return if ref($node) ne 'HASH';
        for my $subkey ( keys %$node ) {
            my $key = $path ? "$path.$subkey" : $subkey;
            my $subnode = $node->{$subkey};
            if ( ref($subnode) eq 'HASH' ) {
                $set->($subnode, $key);
            }
            else {
                $node->{$subkey} = $cgi->param($key);
            }
        }
    };

    $set->($c);
    return $c;
}


sub configure {
    my ($self, $args) = @_;
    my $cgi = $self->{'cgi'};

    if ( $cgi->param('save') ) {
        my $c = get_form_config($cgi);
        $self->store_data({ c => encode_json($c) });
        print $self->{'cgi'}->redirect(
            "/cgi-bin/koha/plugins/run.pl?class=Koha::Plugin::Tamil::Electre&method=tool");
    }
    else {
        my $template = $self->get_template({ file => 'configure.tt' });
        $template->param( c => $self->config() );
        $self->output_html( $template->output() );
    }
}


sub tool {
    my ($self, $args) = @_;

    my $cgi = $self->{cgi};

    my $template;
    my $c = $self->config();
    my $ws = $cgi->param('ws');
    if ( $ws ) {
    }
    else {
        $template = $self->get_template({ file => 'home.tt' });
        my $cache = $self->{cache};
        my $key = "tamelec-home";
        my $markdown = $cache->get_from_cache($key);
        unless ($markdown) {
            my $text = $self->mbf_read("home.md");
            utf8::decode($text);
            my $response = Pithub::Markdown->new->render(
                data => {
                    text => $text,
                    context => "github/gollum",
                },
            );
            $markdown = $response->raw_content;
            utf8::decode($markdown);
            $cache->set_in_cache($key, $markdown, { expiry => 3600 });
        }
        $template->param( markdown => $markdown );
    }
    $template->param( c => $self->config() );
    $template->param( WS => $ws ) if $ws;
    $self->output_html( $template->output() );
}


sub opac_js {
    my $self = shift;
    my $js_file = $self->get_plugin_http_path() . "/electre.js";
    my $c = $self->config();
    $c->{api} = undef; # Cacher à l'OPAC les infos de connexion à l'API Electre
    my $conf = to_json($c);
    return <<EOS;
<script>
\$(document).ready(() => {
    \$.getScript("$js_file")
        .done(() => \$.tamilElectre($conf));
    });
</script>
EOS
}


sub api_namespace {
    return 'tamelec';
}


sub api_routes {
    my $self = shift;
    my $spec_str = $self->mbf_read('openapi.json');
    my $spec     = decode_json($spec_str);
    return $spec;
}


sub install() {
    my ($self, $args) = @_;
}


sub upgrade {
    my ($self, $args) = @_;

    my $dt = DateTime->now();
    $self->store_data( { last_upgraded => $dt->ymd('-') . ' ' . $dt->hms(':') } );

    return 1;
}


sub uninstall() {
    my ($self, $args) = @_;
}

1;
