
# setup Perl to use local::lib package location to persist CPAN packages across
# perl upgrades

setup_perl_local_lib() {
	local lib_dir="$1"
	[ $(homebrew_which perl) ] && [ -d "$lib_dir" ] && {
		eval "$(perl -I${lib_dir} -Mlocal::lib)"
		return
	} || true
}

setup_perl_local_lib "$HOME/perl5/lib/perl5"
