Advanced Scala with Scalaz
--------------------------

Getting Started
---------------

You'll need to install the grunt project dependencies the first time you check the project out:

~~~
brew install pandoc
npm install -g grunt-cli coffee-script
npm install
~~~

Building
--------

Use the following commands to build a single format:

~~~
grunt pdf
grunt html
grunt epub
~~~

The default grunt behaviour is to build all formats:

~~~
grunt
~~~

All targets are placed in the `dist` directory.

Run the following to build all formats, start a web server to serve them,
and rebuild if you change any files:

~~~
grunt watch
~~~
