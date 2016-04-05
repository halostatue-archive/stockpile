### 2.0 / 2016-04-04

*   1 major change

    *    Dropped support for Ruby 1.9 families.

*   1 bugfix

    *    Fix [stockpile-redis issue #1][]. Although not reported against
         Stockpile, this issue was caused by calling #fetch (and #delete)
         against an OpenStruct options object in any instance of
         Stockpile::Base.

*   1 governance change

    *    Add a Code of Conduct based on the Contributor's Covenant 1.4.

*   Miscellaneous

    *    Added Rubocop.

### 1.1 / 2015-02-10

* 3 minor enhancements

  * Created a base adapter, Stockpile::Base, that implements the core public
    interface of a connection manager in a consistent way for argument parsing.

  * Created a memory adapter as an example adapter. (This had previously been
    a test adapter created in the test environment.)

  * Documented changes to how clients can be specified for Stockpile.new,
    Stockpile#connect, and Stockpile#connection_for.

* 1 bugfix

  * Fix [issue #2][], where
    the use of the cache adapter causes the Stockpile cache manager to
    initialize too early.

### 1.0 / 2015-01-21

* 1 major enhancement

  * Birthday!

[issue #2]: https://github.com/halostatue/stockpile/issues/2
[stockpile-redis issue #1]: https://github.com/halostatue/stockpile-redis/issues/1
