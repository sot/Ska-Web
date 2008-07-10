# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Ska-Web.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { use_ok('Ska::Web') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

($user, $passwd) = Ska::Web::get_user_passwd('/proj/sot/ska/data/aspect_authorization/occweb-*');
ok((defined $user) && (defined $passwd), "Get authorization\n");
