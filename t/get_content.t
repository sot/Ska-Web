# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Ska-Web.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('Ska::Web') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

($content, $error) = Ska::Web::get_url_content('http://asc.harvard.edu/mta/G11.html',
					       filter => {tag => 'ul'},
					   );
ok(defined $content and not defined $error);

($content, $error) = Ska::Web::get_url_content('http://asc.harvard.edu/mta/G11.html',
					       pre => 'Proton Flux',
					       post => 's-sr-MeV',
					       filter => {tag => 'pre'},
					   );
ok(defined $content and not defined $error);

($content, $error, @images) = Ska::Web::get_url_content('http://asc.harvard.edu/mta/G11.html',
							filter => {tag => 'img',
								   alt => 'space weather'
								  }
						       );
ok(defined $content and not defined $error and @images);

($content, $error, @images) = Ska::Web::get_url_content("file:///$ENV{PWD}/t/get_content.t",
							pre => 'Insert your\s+test code',
							post => 'script.$');
ok(defined $content and not defined $error and not @images);

