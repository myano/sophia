::

#                   _     _       
#   ___  ___  _ __ | |__ (_) __ _ 
#  / __|/ _ \| '_ \| '_ \| |/ _` |
#  \__ \ (_) | |_) | | | | | (_| |
#  |___/\___/| .__/|_| |_|_|\__,_|
#  ----------|_|------------------
#
#       sophia Perl IRC bot

Table of Contents
-----------------
    1. `Pre-requisites`_
    2. `Install`_
    3. `Run`_
    4. `Trouble / Help`_
    5. `Contributions`_
    6. `License`_


Pre-requisites
--------------

- libcurl-dev
- libxml-dev

Note: While not required, ``cpanm`` is strongly recommended for building sophia's
Perl dependencies in a simple way. local::lib is also recommended unless you
do not mind installing all of `sophia`'s Perl dependencies in system directories.
In other words, running as root (sudo).


Install
-------

With the original tarball: ``cpanm sophia-3.0.tar.gz``
That will build all the Perl dependencies. It may take a while to complete.
After that is completed, you can launch ``bin/sophia`` from the extracted directory
from wherever you want. See Run below for more details.


Run
---

You need to set a configuration file. Copy ``etc/sophia.conf.example`` to ``etc/sophia.conf``.
Once you copy this file, open it up and change the necessary settings.
Also if you want all the modules to load on start, copy ``etc/sophia.modules.conf.example`` to ``etc/sophia.modules.conf``.
To launch `sophia` run ``./bin/sophia``


Trouble / Help
--------------

You can reach the development team on `freenode <http://freenode.net/>`_ in `##sophia <http://webchat.freenode.net/?channels=##sophia>`_


Contributions
-------------

- Kays
- yano


License
-------

`sophia` is licensed under the `GNU GPL License version 3 <http://www.gnu.org/licenses/gpl-3.0.html>
A fully copy of the license can be found in the LICENSE file.
