
# setup Perl to use local::lib package location to persist CPAN packages across
# perl upgrades
[ $(which perl 2> /dev/null) ] &&\
	[ -d "$HOME/perl5/lib/perl5" ] &&\
	eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)"
