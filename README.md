# CS2J : C# to Java conversion tool

### Introduction

CS2J is the most advanced C# to Java conversion tool available today.
 
* CS2J produces good looking, maintainable Java software from your C#
  source code.
* It uses a powerful, extensible template system to translate .NET
  Framework and 3rd party library calls.
* It is a command-line tool which can be easily incorporated into your
  existing development workflow.
* And it is completely Open Source!

CS2J was initially developed by Rustici Software to translate their
SCORM Engine web application (http://www.scorm.com), it was later 
developed and marketed by Twiglet Software as a general purpose
C# to Java application translator.  We are now pleased to be able
to make the source code freely available.

The CS2J source distribution has two components:

* **CSharpTranslator**:

     This builds the *cs2j.exe executable*.  This executable runs
     directly under **Windows** and under **Mono** on other platforms
     (http://www.mono-project.com/Main_Page).

     This work is licensed under the **MIT / X Window System License**
     (http://opensource.org/licenses/mit-license.php). 

     With this license the produced Java code is completely unencumbered 
     and you can do **what you want** with it.

* **CS2JLibrary**: 

     This contains the *XML translation files* that direct cs2j to
     translate **.Net framework** calls into appropriate **Java** code, and
     the *CS2JLibrary Java support library* that should be deployed with
     translated applications.
     
     ***Note that the XML folder is now in CSharpTranslator directory, and part
     of the Visual Studio project.***

     This work is licensed under the Apache License, Version 2.0
     (http://www.apache.org/licenses/LICENSE-2.0).
     

### How it works

The way CS2J translate your C# application can be sliced in 4 parts :

* The creation of an **environment** based on *XML translation files* and *your C# application*. This environment allows CS2J to make **links** between your classes, and the transformations to perform. 
This work is done by **TemlateExtracter**.

Then for each file.cs:

* **JavaMaker** parses the file and creates a first *AST* (Abstract Syntax Tree)
* **NetMaker** parses the first tree, *convert most of .NET call into its Java equivalent* and create a second *AST*
* **JavaPrettyPrint** parses the second tree, finalizes the translation, and creates a *human readable code* which will be saved into *file.java*.

### How to modify a translation / add your own

As was said before, translations are, for the biggest part, done using XML.
To modify / add some content, you should modify the XML, but it is awful to modify huge files, and worse to create your own. That's why Ijinus created an edition tool : [CS2JXmlEditor](https://github.com/MathieuBlond-Ijinus/CS2JXmlEditor).

We recommend you to use this tool in order to respect the XML schema definition (which is at the moment not the case of all the XML).
