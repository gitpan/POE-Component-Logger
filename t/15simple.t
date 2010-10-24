# Test our Log::Dispatch/Log::Dispatch::Config testing infrastructure
# Author: Olivier Mengué <dolmen@cpan.org>

use strict;
use warnings;
use Test::NoWarnings;
use Test::More tests => 38;

my @tests;

BEGIN {
    @tests = (
        { level => warning => message => '1. Warning' },
        { level => error => message => '2. Error' },
        { level => warning => message => '3. Warning' },
        { level => error => message => '4. Error', TODO => 'Fix this race case' },
        { level => critical => message => '5. Critical', TODO => 'Fix this race case' },
        { level => warning => message => '6. Warning' },
        { level => warning => message => '7. Warning' },
        { level => debug => message => '8. Debug' },
        { level => info => message => '9. Info' },
        { level => notice => message => '10. Notice' },
        { level => warning => message => '11. Warning' },
        { level => error => message => '12. Error' },
        { level => critical => message => '13. Critical' },
        { level => alert => message => '14. Alert' },
        { level => emergency => message => '15. Emergency' },
    );
}

use t::lib::Log::Dispatch::Config::Test \@tests;

use POE;
use POE::Component::Logger;

is $POE::Component::Logger::DefaultLevel, 'warning', 'DefaultLevel';

POE::Component::Logger->spawn(
    ConfigFile => t::lib::Log::Dispatch::Config::Test->configurator);

is $POE::Component::Logger::DefaultLevel, 'warning', 'DefaultLevel';

POE::Session->create(
    inline_states => {
        _start => sub {
            pass "_start";
            $poe_kernel->yield('evt1');
        },
        evt1 => sub {
            Logger->log({ level => warning => message => '1. Warning'});
            $poe_kernel->yield('evt2');
        },
        evt2 => sub {
            Logger->log({ level => error => message => '2. Error'});

            is $POE::Component::Logger::DefaultLevel, 'warning', 'DefaultLevel';
            # Log at default level
            Logger->log('3. Warning');
            $poe_kernel->yield('evt3');
        },
        evt3 => sub {
            # The problem is that the DefaultLevel should be retrieved
            # synchronously at the Logger->log call instead of in the POE
            # event handler
            {
                local $POE::Component::Logger::DefaultLevel = 'error';
                Logger->log('4. Error');
                local $POE::Component::Logger::DefaultLevel = 'critical';
                Logger->log('5. Critical');
            }
            $poe_kernel->yield('evt4');
        },
        evt4 => sub {
            # We should be back at DefaultLevel
            is $POE::Component::Logger::DefaultLevel, 'warning', 'DefaultLevel';
            Logger->log('6. Warning');
            $poe_kernel->post('logger', 'log', '7. Warning');
            $poe_kernel->yield('evt5');
        },
        evt5 => sub {
            $poe_kernel->post('logger', 'debug', '8. Debug');
            $poe_kernel->post('logger', 'info', '9. Info');
            $poe_kernel->post('logger', 'notice', '10. Notice');
            $poe_kernel->post('logger', 'warning', '11. Warning');
            $poe_kernel->post('logger', 'error', '12. Error');
            $poe_kernel->post('logger', 'critical', '13. Critical');
            $poe_kernel->post('logger', 'alert', '14. Alert');
            $poe_kernel->post('logger', 'emergency', '15. Emergency');
        },
        _stop => sub {
            pass "_stop";
        },
    },
);

POE::Kernel->run;

pass "POE kernel shutdown";

# vim: set et ts=4 sw=4 sts=4 :
