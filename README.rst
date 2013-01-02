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
    1. `Install`_
    2. `Run`_
    3. `Trouble / Help`_
    4. `Contributions`_
    5. `License`_


Install
-------

sophia should work out of the box. sophia does use quite a bit of CPAN modules.
An archive of CPAN modules is included with sophia in the cpan directory.
Just extract that tarball into the cpan directory.
Make sure that the extracted files are in the cpan directory.
cd cpan
tar -jxf cpan.tar.bz2

You need to set a configuration file. Copy ``etc/sophia.conf.example`` to ``etc/sophia.conf``.
Once you copy this file, open it up and change the necessary settings.
Also if you want all the modules to load on start, copy ``etc/sophia.modules.conf.example`` to ``etc/sophia.modules.conf``.


Run
---

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

`sophia` is licensed under the `Eiffel Forum License version 2 <https://www.gnu.org/licenses/eiffel-forum-license-2.html>`_.
A fully copy of the license can be found in the LICENSE file.
