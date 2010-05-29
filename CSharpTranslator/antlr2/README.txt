                                       Welcome to CS2J, a C# to Java translator

In this directory you will find:

Translator:  A C# project that can be built in Visual Studio 2005.  It requires a version of Antlr that can generate C# to be on 
your path. It builds to a command line application. Run it without arguments to see how to use it to translate C# projects to Java.
Although the project knows to use antlr to build the grammar files VS2005 has trouble with getting the dependencies straight. For
a trouble free development I suggest you run MSBuild directly in the project directory, e.g.:

   kevin.glynn@D11624C1 ~/winhome/My Documents/Visual Studio 2005/Projects/Translator/Translator
   $ /cygdrive/c/WINDOWS/Microsoft.NET/Framework/v2.0.50727/MSBuild.exe 

works for me under cygwin.

In order that the -show<etc> options work you will need to add antlr.astframe.dll and antlr.runtime.dll (from the antlr distribution)
to your project references.


CS2JLibrary:  These are the XML translation files for the .NET library.  Copy them into your filesystem, this location will be passed
as your translator's -netdir argument.

CS2JLibrary: This is a Java project containing supporting code that will be required by the translated code to build and
run.  Load it into a project in your Java environment and make your translated project depend on it.

   
Disclaimer: By the way, the translator doesn't quite work yet ....

Kevin (kevin.glynn@scorm.com)