package Dist::Zilla::Plugin::ModuleBuild::XSOrPP;
{
  $Dist::Zilla::Plugin::ModuleBuild::XSOrPP::VERSION = '0.03';
}

use strict;
use warnings;

use Moose;

use Dist::Zilla 4.0 ();

extends
    qw( Dist::Zilla::Plugin::ModuleBuild Dist::Zilla::Plugin::InlineFiles );

my $pp_check = <<'EOF';
my $skip_xs;
if ( grep { $_ eq '--pp' } @ARGV ) {
    $skip_xs = 1;
}
elsif ( ! can_xs() ) {
    $skip_xs = 1;
}

if ($skip_xs) {
    $build->build_elements(
        [ grep { $_ ne 'xs' } @{ $build->build_elements() } ] );
}

sub can_xs {
    # Do we have the configure_requires checker?
    local $@;
    eval "require ExtUtils::CBuilder;";
    if ($@) {

        # They don't obey configure_requires, so it is
        # someone old and delicate. Try to avoid hurting
        # them by falling back to an older simpler test.
        return can_cc();
    }

    # Do a simple compile that consumes the headers we need
    my @libs    = ();
    my $object  = undef;
    my $builder = ExtUtils::CBuilder->new( quiet => 1 );
    unless ( $builder->have_compiler ) {

        # Lack of a compiler at all
        return 0;
    }
    eval {
        $object = $builder->compile(
            source => 'sanexs.c',
        );
        @libs = $builder->link(
            objects     => $object,
            module_name => 'sanexs',
        );
    };
    my $broken = !!$@;
    foreach ( $object, @libs ) {
        next unless defined $_;
        1 while unlink $_;
    }

    if ($broken) {
        ### NOTE: Don't do this in a production release.
        # Compiler is officially screwed, you don't deserve
        # to do any of our downstream depedencies as you'll
        # probably end up choking on them as well.
        # Trigger an NA for their own protection.
        print "Unresolvable broken external dependency.\n";
        print "This package requires a C compiler with full perl headers.\n";
        print "Trivial test code using them failed to compile.\n";
        print STDERR "NA: Unable to build distribution on this platform.\n";
        exit(0);
    }

    return 1;
}

sub can_cc {
    my @chunks = split( / /, $Config::Config{cc} ) or return;

    # $Config{cc} may contain args; try to find out the program part
    while (@chunks) {
        return can_run("@chunks") || ( pop(@chunks), next );
    }

    return;
}

sub can_run {
    my ($cmd) = @_;

    my $_cmd = $cmd;
    if ( -x $_cmd or $_cmd = MM->maybe_command($_cmd) ) {
        return $_cmd;
    }

    foreach my $dir ( ( split /$Config::Config{path_sep}/, $ENV{PATH} ), '.' )
    {
        next if $dir eq '';
        my $abs = File::Spec->catfile( $dir, $cmd );
        return $abs if ( -x $abs or $abs = MM->maybe_command($abs) );
    }

    return;
}
EOF

after setup_installer => sub {
    my $self = shift;

    my ($file) = grep { $_->name() eq 'Build.PL' } @{ $self->zilla()->files() };

    my $content = $file->content();

    $content =~ s/(\$build->create_build_script;)/$pp_check$1/;

    $file->content($content);

    return;
};

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Add a --pp option to your Build.PL to force an XS-less build



=pod

=head1 NAME

Dist::Zilla::Plugin::ModuleBuild::XSOrPP - Add a --pp option to your Build.PL to force an XS-less build

=head1 VERSION

version 0.03

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut


__DATA__
___[ sanexs.c ]___
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int main(int argc, char **argv) {
    return 0;
}

int boot_sanexs() {
    return 1;
}

__END__

=head1 SYNOPSIS

In your F<dist.ini>:

   [ModuleBuild::XSOrPP]

=head1 DESCRIPTION

Use this plugin instead of the regular C<ModuleBuild> plugin. It generates a
F<Build.PL> which is smart about building XS. It can accept a C<--pp> flag to
forcibly disable XS compilation. If no flag is passed, it tests whether the
installing machine has a working compiler, and disables XS if this test fails.

Obviously, this is only useful if your module can work without its XS
component.

=head1 SUPPORT

Please report any bugs or feature requests to
C<bug-dist-zilla-plugin-modulebuild-xsorpp@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org>. I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 CREDITS

Much of the compiler check code comes from the F<Makefile.PL> in the
L<List::MoreUtils> distro.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module, please
consider making a "donation" to me via PayPal. I spend a lot of free time
creating free software, and would appreciate any support you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order for me
to continue working on this particular software. I will continue to do so,
inasmuch as I have in the past, for as long as it interests me.

Similarly, a donation made in this way will probably not make me work on this
software much more, unless I get so many donations that I can consider working
on free software full time, which seems unlikely at best.

To donate, log into PayPal and send money to autarch@urth.org or use the
button on this page: L<http://www.urth.org/~autarch/fs-donation.html>

=cut
