require "mixlib/shellout"
require "ruby-prof"
RubyProf.start
c = Mixlib::ShellOut.new(["false", "--system", "is-enabled", "sysstat-collect\\x2d.timer"])
c.run_command
result = RubyProf.stop
printer = RubyProf::FlatPrinter.new(result)
printer.print(STDOUT)
