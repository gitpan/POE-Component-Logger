# $Id: Logger.pm,v 1.1.1.1 2002/01/10 20:48:53 matt Exp $

package POE::Component::Logger;
use strict;

use POE;
use Log::Dispatch::Config;

use vars qw($VERSION $DefaultLevel);

$VERSION = '1.00';

$DefaultLevel = 'warning';

sub spawn {
    my $class = shift;
    POE::Session->create(
        inline_states => {
            _start => \&start_logger,
            _stop => \&stop_logger,
            
            # more states here for logging of different levels?
            log => \&poe_log,
            debug => sub { local $DefaultLevel='debug'; poe_log(@_)},
            info => sub { local $DefaultLevel='info'; poe_log(@_)},
            notice => sub { local $DefaultLevel='notice'; poe_log(@_)},
            warning => sub {local $DefaultLevel='warning'; poe_log(@_)},
            error => sub { local $DefaultLevel='error';poe_log(@_)},
            critical => sub { local $DefaultLevel='critical';poe_log(@_)},
            alert => sub { local $DefaultLevel='alert';poe_log(@_)},
            emergency => sub {local $DefaultLevel='emergency';poe_log(@_)},
        },
        args => [ @_ ],
    );
}

sub start_logger {
    my ($kernel, $heap, %args) = @_[KERNEL, HEAP, ARG0 .. $#_];
    
    $args{Alias} ||= 'logger';
    
    Log::Dispatch::Config->configure($args{ConfigFile});
    
    $heap->{_logger} = Log::Dispatch->instance;
    $heap->{_alias} = $args{Alias};
    $kernel->alias_set($args{Alias});
}

sub stop_logger {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    
    $kernel->alias_remove($heap->{_alias});
    delete $heap->{_logger};
}

sub poe_log {
    my ($heap, $arg0, @args) = @_[HEAP, ARG0, ARG1..$#_];
    
    if (ref($arg0)) {
        $heap->{_logger}->log(%$arg0);
    }
    else {
        $heap->{_logger}->log(
            level => $DefaultLevel,
            message => join('', $arg0, @args),
            );
    }
}

sub log {
    my $class = shift;
    POE::Session->create(
        inline_states => {
            _start => \&start_logging,
        },
        args => [ @_ ],
    );
}

*Logger::log = \&log;

sub start_logging {
    my ($kernel, @args) = @_[KERNEL, ARG0..$#_];
    $kernel->post(logger => log => @args);
}

1;
__END__

=head1 NAME

POE::Component::Logger - A POE logging class

=head1 SYNOPSIS

In your startup code somewhere:

  POE::Component::Logger->spawn(ConfigFile => 'log.conf');

And later in an event handler:

  Logger->log("Something happened!");

=head1 DESCRIPTION

POE::Component::Logger provides a simple logging component
that uses Log::Dispatch::Config to drive it, allowing you
to log to multiple places at once (e.g. to STDERR and Syslog
at the same time) and also to flexibly define your logger's
output.

It is very simple to use, because it creates a Logger::log
method (yes, this is namespace corruption, so shoot me). If
you don't like this, feel free to post directly to your
logger as follows:

  $kernel->post('logger', 'log', "An error occurred: $!");

In fact you have to use that method if you pass an Alias
option to spawn (see below).

All logging is done in the background, so don't expect
immediate output - the output will only occur after control
goes back to the kernel so it can process the next event.

=head1 OPTIONS and METHODS

=head2 spawn

The spawn class method can take two options. A required
B<ConfigFile> option, which specifies the location of the
config file as passed to Log::Dispatch::Config's
C<configure()> method (note that you can also use an object
here, see L<Log::Dispatch::Config> for more details). The
other available option is B<Alias> which you can use if you
wish to have more than one logger in your POE application.
Note though that if you specify an alias other than the
default 'logger' alias, you will not be able to use the
C<Logger-E<lt>log> shortcut, and will have to use direct
method calls instead.

=head2 Logger->log

This is used to perform a logging action. You may either
pass a string, or a hashref. If you pass in a string it
is logged at the level specified in
C<$POE::Component::Logger::DefaultLevel>, which is
'warning' by default. If you pass in a hashref it is passed
as a hash to Log::Dispatch's C<log()> method.

=head1 LOGGING STATES

The following states are available on the logging session:

=head2 log

Same as C<Logger-E<lt>log()>, except you may use a different
alias if posting direct to the kernel, for example:

  $kernel->post( 'error.log', 'log', "Some error");
  $kernel->post( 'access.log', 'log', "Access Details");

=head2 debug

And also C<notice> C<warning>, C<info>, C<error>, C<critical>,
C<alert> and C<emergency>.

These states simply log at a different level. See
L<Log::Dispatch> for further details.

=head1 EXAMPLE CONFIG FILE

  # logs to screen (STDERR) and syslog
  dispatchers = screen syslog

  [screen]
  class = Log::Dispatch::Screen
  min_level = info
  stderr = 1
  format = %d %m %n

  [syslog]
  class = Log::Dispatch::Syslog
  min_level = warning

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 BUGS

Please use http://rt.cpan.org/ for bugs.

=head1 LICENSE

This is free software. You may use it and redistribute it
under the same terms as Perl itself.

=head1 SEE ALSO

L<Log::Dispatch>

L<Log::Dispatch::Config>

L<AppConfig>

L<POE>

=cut

