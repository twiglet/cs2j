header
{
	using System.Globalization;
}

options
{
	language 	= "CSharp";	
	namespace   = "RusticiSoftware.Translator";
}

/*
[The "BSD licence"]
Copyright (c) 2002-2005 Kunle Odutola
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


/// <summary>
/// The basic building block of C# Preprocessors and Lexers.
/// </summary>
///
/// <remarks>
/// <para>
/// The Lexer defined below is effectively an abstract base class that collects together a
/// number of rules that are useful to all Preprocessors and Lexers for the C# language.
/// </para>
///
/// <para>
/// History
/// </para>
///
/// <para>
/// 26-Jan-2003 kunle      Derived this Lexer from the original combined grammar <br/>
/// </para>
///
/// </remarks>


*/
class CSharpLexerBase extends UnicodeLexerBase;

options
{
	importVocab							= UnicodeLexerBase;
	exportVocab							= CSharpLexerBase;
	charVocabulary						= '\u0000'..'\uFFFE';	// All UNICODE characters except \uFFFF [and \u0000 to \u0002 used by ANTLR]
	k									= 2;
	testLiterals						= false;   				// don't automatically test for literals
	defaultErrorHandler					= false;
}

tokens
{
	TRUE		= "true";
	FALSE		= "false";
	DEFAULT		= "default";

	PP_DEFINE;
	PP_UNDEFINE;
	PP_COND_IF;
	PP_COND_ELIF;
	PP_COND_ELSE;
	PP_COND_ENDIF;
	PP_LINE;
	PP_ERROR;
	PP_WARNING;
	PP_REGION;
	PP_ENDREGION;
	
	PP_FILENAME;
	PP_IDENT;
	PP_STRING;
	PP_NUMBER;
	
	WHITESPACE;
}

//======================================
// Start of Lexer Rules
//======================================

// The following group of rules are shared by C# Preprocessors and Lexers
QUOTE			:	'"'		;
OPEN_PAREN		: 	'('		;
CLOSE_PAREN		: 	')'		;
LOG_NOT			: 	'!'		;
LOG_AND			: 	"&&"	;
LOG_OR			: 	"||"	;
EQUAL			: 	"=="	;
NOT_EQUAL		: 	"!="	;


//======================================
// Section A.1.3 Comments
//
SL_COMMENT
	:	"//" ( NOT_NEWLINE )* (NEWLINE)?
	;

//======================================
// Section A.1.1 Line terminators
//
//protected 
NEWLINE
	:	( '\r' 									// MacOS-style newline
		  ( options { generateAmbigWarnings=false; } 
		    : '\n' 								// DOS/Windows style newline
		  )?
		| '\n'									// UNIX-style newline
		| '\u2028'								// UNICODE line separator
		| '\u2029'								// UNICODE paragraph separator
		)					
		{ newline(); }
	;

protected NOT_NEWLINE
	: ~( '\r' | '\n' | '\u2028' | '\u2029'	)
	;


//======================================
// Section A.1.2 White space
//

protected NON_NEWLINE_WHITESPACE
	:	'\t'			// horiz_tab
//	|	' '				// space -- commented out because UNICODE_CLASS_Zs contains space too
	| 	'\f'			// form_feed
	| 	'\u000B'		// '\u000B' == '\v' == vert_tab
	| 	UNICODE_CLASS_Zs	
	;


//======================================
// Section A.1.5 Unicode character escape sequences
//
protected UNICODE_ESCAPE_SEQUENCE
	: 	'\\'
	   ( 'u' HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT
	   | 'U' HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT HEX_DIGIT
	   )
	;


protected DECIMAL_DIGIT
	:	('0'..'9')
	;
		
protected HEX_DIGIT
	:	('0'..'9'|'A'..'F'|'a'..'f')
	;


protected LETTER_CHARACTER   
	:  UNICODE_CLASS_Lu 
	|  UNICODE_CLASS_Ll 
	|  UNICODE_CLASS_Lt 
	|  UNICODE_CLASS_Lm 
	|  UNICODE_CLASS_Lo 
	|  UNICODE_CLASS_Nl
	;

protected DECIMAL_DIGIT_CHARACTER
	:	UNICODE_CLASS_Nd
	;
	
protected CONNECTING_CHARACTER
	:	UNICODE_CLASS_Pc
	;
	
protected COMBINING_CHARACTER
	:	UNICODE_CLASS_Mn 
	|	UNICODE_CLASS_Mc
	;
	
protected FORMATTING_CHARACTER
	:	UNICODE_CLASS_Cf
	;
	
