::

#                   _     _       
#   ___  ___  _ __ | |__ (_) __ _ 
#  / __|/ _ \| '_ \| '_ \| |/ _` |
#  \__ \ (_) | |_) | | | | | (_| |
#  |___/\___/| .__/|_| |_|_|\__,_|
#  =========~|_|~=================
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

Run ``./configure`` to make sure you have the required packages installed. If you do not have the required packages you can install them through your distribution's repositories or `CPAN <http://www.cpan.org/>`_.

You need to set a configuration file. Copy ``etc/sophia.conf.example`` to ``etc/sophia.conf``. Once you copy this file, open it up and change the necessary settings. Also if you want all the modules to load on start, copy ``etc/sophia.modules.conf.example`` to ``etc/sophia.modules.conf``.


Run
---

To launch `sophia` run ``./bin/`sophia```


Trouble / Help
--------------

If you need to re-generate a configuration file run ``./bin/genconfig``.

You can reach the development team on `Freenode <http://freenode.net/>`_ in `##sophia <http://webchat.freenode.net/?channels=##sophia>`_


Contributions
-------------

- Kays
- yano

If you have any feature suggestions or if you would like a feature that you wrote to be included in `sophia`, please contact us.


License
-------

`sophia` is licensed under the `Eiffel Forum License version 2 <https://www.gnu.org/licenses/eiffel-forum-license-2.html>`_. A fully copy of the license can be found in the LICENSE file.
