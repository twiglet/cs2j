kcsparse - a ECMA-334 C# Grammar Sample for ANTLR 2.7.7

1 December, 2005

Kunle Odutola		: kunle UNDERSCORE odutola AT hotmail DOT com
Micheal Jordan


1. INTRODUCTION 

Congratulations, you have found 'kcsparse' - a nice YAC#GFA[*]!

We hope you find 'kcsparse' delightful and useful even but, as per the 
license under which you may use it, this software is not guaranteed to 
work. See LICENSE.TXT for the full text of the license.

----------------------------------------------------------------------
THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
----------------------------------------------------------------------


2. WHAT'S A YAC#GFA?

Yet Another C# Grammar For ANTLR.

This particular example is called 'kcsparse' and we hope you like it. 

It is probably a more complete and usable YAC#GFA than others. It is 
deliberately packaged in the style of the samples that are included with 
ANTLR itself (and may become one of the standard samples). In any event, 
it should just work out-of-the box for many C# source files.

2.1 WHAT kcsparse CAN DO
	- Parse C# 1.x source code including some with C# preprocessing directives.
	
	- Build an AST from the C# source.
	
	- Display the AST it builts from C# source.
	
	- Unparse the AST (i.e. pretty prints the AST) back to source code.
	
2.2 WHAT kcsparse CAN'T DO?
	- Full parse and resolve of the input C# source code.
	  (kcsparse is NOT a C# front-end but, you can build one based on it)
	  
	- Parse all C# 1.x source code (esp. those with use of preprocessing directives).
	  (kcsparse is NOT a full C# 1.0 parser - it particularly fails on C# source 
	   files where simply deleting (or commenting out) all preprocessing directives 
	   results in illegal C# source but, you extend it to be)
	  
	- Parse C# source code with C# 2.0 or later features like generics.
	  (kcsparse is NOT a C# 2.0 parser but, you extend it to be)
	  
	- Compile C# source code to MSIL, bytecode or any other lanaguage 
	  (kcsparse is NOT a C# translator/compiler but, you can build one based on it)
	  
	- Interpret C# source code
	  (kcsparse is NOT a C# interpreter but, you can build one based on it)
	  
	- Mow your lawns or fetch you a cold beer
	  (But we would like it to be!)


3. WHAT'S IN THE PACK?

Along with this with file, you should have received the following:

	README.TXT							This file
	LICENSE.TXT							Our license for this software
	csharp_v1.build						NAnt build file
	CSharpLexer.g						Main C# lexer grammar file
	CSharpPreprocessorLexer.g			C# lexer grammar file (used for preprocessor directives)
	CSharpPreprocessorHooverLexer.g		C# lexer grammar file (used for preprocessor directives)
	CSharpLexerBase.g					Common base for all C# lexer grammars
	UnicodeLexerBase.g					Common base for unicode-savvy lexer grammars
	CSharpParser.g						C# parser grammar file
	CSharpPrettyPrinter.g				C# pretty printer grammar file
	CustomHiddenStreamToken.cs			Custom IToken class
	ASTNode.cs							Custom AST node class
	ASTNodeFactory.cs					Custom ASTFactory class
	CodeMaskEnums.cs					Helper class
	Main.cs								Contains sample parsing application
	csharp.flex							Lexer grammar file for use with C# Flex 
	testfiles							Directory containing test files to test C# parsing
	    AllCSharpConstructs.cs
	    Empty.cs
	    EmptyNamespace.cs
	    Testing.cs
	    Using.cs
	    UsingGlobalAttributes.cs
	Tools
		csflex.exe						C# Flex executable
		runtime.dll						[supplied with C# Flex]


4. USING kscparse

The easiest way to use kcsparse is to unpack the files into a directory below
the %ANTLR_HOME%/examples/csharp/ directory. This would "install" it just like
any of the other ANTLR C# examples. Be sure to maintain the directory
structure of the archive as shown above. 

Then, just type 'nant' (without the single quotes) to build and try kcsparse.
This assumes that the ANTLR C# runtimes files have been compiled and are in the
expected location.

Once it is built, you can also run kcsparse directly yourself:
	kcsparse <filename>							-- parse the specified <filename>
	
	kcsparse -flex <filename>					-- parse the specified <filename> (uses flex lexer)
	
	kcsparse <directory>						-- parse all *.cs files in <directory>
	
	kcsparse -flex <directory>					-- parse all *.cs files in <directory> (uses flex lexer)
	
	kcsparse -showtree <file_or_directory>		-- parse all *.cs files in <file_or_directory> and 
												   display the AST
												   
	kcsparse -prettyprint <filename>			-- parse <filename> and unparse (pretty-print)
												   the AST to the console

	kcsparse -flex -prettyprint <filename>		-- parse <filename> and unparse (pretty-print)
												   the AST to the console (uses flex lexer)


5. kscparse STATUS

kcsparse still has some bugs. kcsparse is mostly complete but expect a few rough edges.

