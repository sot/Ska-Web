# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Ska-Web.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('Ska::Web') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

($html, $error) = Ska::Web::get_url('http://www.google.com');
ok((not defined $error), "Get google home page\n");
($html, $error) = Ska::Web::get_url('http://sunsite.dcc.uile.cl/chile/chile.html',
				    timeout => 10);
ok((defined $error), "Get invalid web site\n");
