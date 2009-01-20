package Splunk::Conf;

use Moose;
use LWP::UserAgent;
use XML::Simple;
use URI;
use URI::Escape;
use Carp;


has url => (
    is => 'ro',
    isa => 'Str',
    default => 'https://localhost:8089/services',
);

has skey => (
    is => 'rw',
    isa => 'Str',
);

has ua => (
    is => 'ro',
    isa => 'LWP::UserAgent',
    lazy => 1,
    default => sub {
        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        $ua->agent('SNS::Splunk.pm(0.1)');
        return $ua;
    }
);

sub _url_for {
    my ( $self, $path ) = @_;
    return $self->url.$path;
}

sub _url_strip {
    my ( $self, $path ) = @_;
    my $base_path = $self->url;
    $path =~ s/^ $base_path //x;
    return $path;
}

sub login {
    my ( $self, $user, $pass ) = @_;

    my $req = HTTP::Request->new( POST => $self->_url_for('/auth/login') );
    $req->content_type('application/x-www-form-urlencoded');
    $req->content('username='.$user.'&password='.$pass);

    my $res = $self->ua->request($req);
    croak 'cannot log in, got: '.$res->status_line unless $res->is_success;

    my $res_d = XMLin($res->content);
    croak 'cannot log in' unless exists $res_d->{sessionKey};

    $self->skey($res_d->{sessionKey});
    return $res_d->{sessionKey};
}

sub req {
    my ( $self, $url, $meth, $body ) = @_;
    $meth = 'GET' unless $meth;
    croak 'not logged in' unless defined $self->skey;
    my $req = HTTP::Request->new( $meth => $self->_url_for($url) );
    $req->header(Authorization => 'Splunk '.$self->skey);
    if ( $body ) {
        if ( ref $body eq 'HASH' ) {
            $req->content( join '&', map { join '=', $_, $body->{$_} } keys %$body );
        }else {
            $req->content( $body );
        }
    }
    my $res = $self->ua->request($req);
    croak $url.': cannot do request '.$res->status_line unless $res->is_success;
    return $res->content;
}

sub path_for {
    my ( $self, @path ) = @_;
    join '/', '/properties', map { uri_escape($_) } @path;
}

sub list {
    my ( $self, @path ) = @_;
    my $list = XMLin($self->req( $self->path_for(@path)))->{entry};
    return map { $list->{$_}->{title} } keys %$list;
}

sub stanza_create {
    my ( $self, $name, $stanza ) = @_;
    $self->req( $self->path_for($name), 'POST', { __stanza => $stanza });
}

# splunk really only sets it to disabled
sub stanza_remove {
    my ( $self, $name, $stanza ) = @_;
    $self->req( $self->path_for($name, $stanza), 'DELETE' );
}

sub stanza_attrib_update {
    my ( $self, $name, $stanza, %kv ) = @_;
    $self->req( $self->path_for($name, $stanza), 'POST', \%kv );
}

sub stanza_attrib_replace {
    my ( $self, $name, $stanza, %kv ) = @_;
    $self->req( $self->path_for($name, $stanza), 'PUT', \%kv );
}

sub stanza_attrib_kv {
    my ( $self, $name, $stanza ) = @_;
    my $list = XMLin($self->req( $self->path_for($name, $stanza)))->{entry};
    return map { $list->{$_}->{title}, $list->{$_}->{content}->{content} } keys %$list;
}

42;
