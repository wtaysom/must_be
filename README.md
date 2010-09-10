# must_be Runtime Assertions

Ruby doesn't have a static type system.  Tests and specs are well and good.  But at the end of the day, Cthulhu reigns and sanity needs checking.  must_be provides runtime assertions in all kinds of delicious Ruby flavors.

You can configure must_be to notify you of trouble in any way imaginable.  Just set `MustBe.notifier` to any proc or other call worthy object.  By default must_be raises an error, but logging and debugging notifiers come included.  Furthermore, you can disable must_be at any time if its performance penalty proves unsatisfactory.

# Examples

Begin with customary oblations:

	require 'rubygems'
	require 'must_be'

Now `Object` has a number of `must`* and `must_not`* methods.  Here are several examples of each.  When an example notifies, the message corresponding to its `MustBe::Note` error is listed on the following comment line (`#=>` or `#~>` for a regexp match).

	!! paste it in here

# Configuration

	!! ENV['MUST_BE__NOTIFIER'], 
	!! ENV['MUST_BE__DO_NOT_AUTOMATICALLY_INCLUDE_IN_OBJECT']