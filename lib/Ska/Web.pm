package Ska::Web;

use 5.008;
use strict;
use warnings;
use LWP::UserAgent;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
				   get_url
				  ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(
		);
our $VERSION = '0.01';

####################################################################################
sub get_url {
####################################################################################
    my $url = shift;
    my %opt = (timeout => 60,
	       @_);

    my $user_agent = LWP::UserAgent->new;
    $user_agent->timeout($opt{timeout});
    my $req = HTTP::Request->new(GET => $url);
    $req->authorization_basic($opt{user}, $opt{passwd})
      if (defined $opt{user} and defined $opt{passwd});

    
    my $response = $user_agent->request($req);
    if ($response->is_success) {
	return wantarray ? ($response->content, undef) : $response->content;
    } else {
	return wantarray ? (undef, $response->status_line) : undef;
    }
}

1;
__END__

=head1 NAME

Ska::Web - Utilities related to Perl web access

=head1 SYNOPSIS

  use Ska::Web qw(get_url);
  ($html, $error) = get_url('http://sec.noaa.gov/rt_plots/xray_5m.html'
                            user   => $username,
                            passwd => $password,
                            timeout => 120, # Seconds
                           );
  $html = get_url('http://sec.noaa.gov/rt_plots/xray_5m.html');

=head1 DESCRIPTION

Currently Ska::Web has only the simple get_url() utility to fetch content from
the web.  This includes the facility to access password-protected sites and set a
timeout (default = 60 seconds). In array context, get_url() returns the content
and any error message.  In scalar context only the content is returned.  In
both cases the content will be undefined if the Web request was not successful.

=head1 EXPORT

None by default.

=head1 AUTHOR

Tom Aldcroft, E<lt>aldcroft@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Tom Aldcroft

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
