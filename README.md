# must_be Runtime Assertions

Ruby doesn't have a static type system.  Tests and specs are well and good.  But at the end of the day, Cthulhu reigns and sanity needs checking.  must_be provides runtime assertions in all kinds of delicious Ruby flavors.

You can configure must_be to notify you of trouble in any way imaginable.  Just set `MustBe.notifier` to any proc or other call worthy object.  By default must_be raises an error, but logging and debugging notifiers come included.  Furthermore, you can disable must_be at any time if its performance penalty proves unsatisfactory.

# Examples

Begin with customary oblations:

	require 'rubygems'
	require 'must_be'

Now `Object` is modified with a number of `must`* methods.  Let's see a few, two examples of each.  The first passes with flying colors.  The second notifies with a `MustBe::Note` error whose message is listed on the comment line (`#=>`):

	!! paste it in here

# Configuration

	!! ENV['MUST_BE__NOTIFIER'], 
	!! ENV['MUST_BE__DO_NOT_AUTOMATICALLY_INCLUDE_IN_OBJECT']