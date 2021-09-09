# QTB2 - Q Test Bench Release II

The Q Test Bench provides supporting functions for writing unit tests
in q, the programming language of kdb+ from [Kx Systems](http://kx.com).

The detailed documentation on how to use it can be found in
[doc/qtb.md](https://github.com/ktsr42/qtb2/blob/master/doc.md).

QTB and all supporting components in this repository are licensed under the
GNU Public License v3, which can be found on the [GNU website](https://www.gnu.org/copyleft/gpl.html).

This is a rewrite of the original [Q Test Bench (qtb)](https:/github.com/ktsr42/qtb). The core user-visible change
from the original implementation is that the test are now held in a special context hierarchy within kdb. The overall
idea and approach are very much the same, just the specialized container for test lambdas has been removed.

