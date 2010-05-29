header
{
	using System.IO;
	using System.Globalization;

	using TokenStreamSelector		        = antlr.TokenStreamSelector;
}

options
{
	language 	= "CSharp";	
	namespace	= "RusticiSoftware.Translator";
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
/// A Preprocessor Lexer for the C# Language
/// </summary>
///
/// <remarks>
/// <para>
/// The Lexer defined below is designed to match and identify only tokens related to the
/// handling of preprocessing directives for the C# language in the source text. It is 
/// designed to match the tokens that can occur after any of the following directives 
/// (on the same line):
/// <list type="bullet">
///		<item>
///			<term>#define</term>
///		</item>
///		<item>
///			<term>#undefine</term>
///		</item>
///		<item>
///			<term>#if</term>
///		</item>
///		<item>
///			<term>#elif</term>
///		</item>
///		<item>
///			<term>#else</term>
///		</item>
///		<item>
///			<term>#endif</term>
///		</item>
///		<item>
///			<term>#line</term>
///		</item>
/// </list>
/// </para>
///
/// <para>
/// This preprocessing lexer is designed to work in tandem with the C# Lexer defined 
/// in the CSharpLexer.g file. In order words, the lexing of all the input not handled
/// here is assumed to be handled by the other C# Lexer. This other C# Lexer may or may 
/// not be aware of C# preprocessing directives. The co-operation is implemented via 
/// ANTLR's TokenStreamSelector mechanism.
/// </para>
///
/// <para>
/// The operation of this C# preprocessing lexer is based on the "C# Language Specification" 
/// as documented in the ECMA-334  standard dated December 2001.
/// </para>
///
/// <para>
/// History
/// </para>
///
/// <para>
/// 26-Jan-2003 kunle      Derived this Lexer from the original combined grammar <br/>
/// 28-Jan-2003 kunle      Retired this Lexer in favour of single-lexer approach <br/>
/// 25-Feb-2003 kunle      Revived this Lexer after issues with single-lexer approach <br/>
/// </para>
///

*/
class CSharpPreprocessorLexer extends CSharpLexerBase;

options
{
	importVocab							= CSharpLexerBase;
	exportVocab							= CSharpPreprocess;
	charVocabulary						= '\u0000'..'\uFFFE';	// All UNICODE characters except \uFFFF [and \u0000 to \u0002 used by ANTLR]
	k									= 3;					// three characters of lookahead
	testLiterals						= false;   				// don't automatically test for literals
	//defaultErrorHandler				= true;
	defaultErrorHandler					= false;
	codeGenMakeSwitchThreshold 		= 5;  // Some optimizations
	codeGenBitsetTestThreshold		= 5;
}

{
	
	/// <summary>
	///   A <see cref="TokenStreamSelector"> for switching between this Lexer and the C#-only Lexer.
	/// </summary>
	private TokenStreamSelector selector_;
	
	/// <summary>
	///   A <see cref="TokenStreamSelector"> for switching between this Lexer and the C#-only Lexer.
	/// </summary>
	public TokenStreamSelector Selector
	{
		get { return selector_;  }
		set { selector_ = value; }
	}

	private FileInfo	_fileinfo = null;

	/// <summary>
	/// Update _fileinfo member whenever filename changes.
	/// </summary>
	public override void setFilename(string f)
	{
		base.setFilename(f);
		_fileinfo = new FileInfo(f);
	}
	
	/// <summary>
	///   Ensures all tokens have access to the source file's details.
	/// </summary>
	protected override IToken makeToken(int t)
	{
		IToken result = base.makeToken(t);
		CustomHiddenStreamToken customToken = result as CustomHiddenStreamToken;
		if ( customToken != null )
		{
			customToken.File = _fileinfo;
		}
		return result;
	}

	public bool IsLetterCharacter(string s)
	{
		return ( (UnicodeCategory.LowercaseLetter == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Ll
		         (UnicodeCategory.ModifierLetter  == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Lm
		         (UnicodeCategory.OtherLetter     == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Lo
		         (UnicodeCategory.TitlecaseLetter == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Lt
		         (UnicodeCategory.UppercaseLetter == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Lu
		         (UnicodeCategory.LetterNumber    == Char.GetUnicodeCategory(s, 1))     //UNICODE class Nl
		        );
	}

	public bool IsIdentifierCharacter(string s)
	{
		return ( (UnicodeCategory.LowercaseLetter      == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Ll
		         (UnicodeCategory.ModifierLetter       == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Lm
		         (UnicodeCategory.OtherLetter          == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Lo
		         (UnicodeCategory.TitlecaseLetter      == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Lt
		         (UnicodeCategory.UppercaseLetter      == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Lu
		         (UnicodeCategory.LetterNumber         == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Nl		         
		         (UnicodeCategory.NonSpacingMark       == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Mn		         
		         (UnicodeCategory.SpacingCombiningMark == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Mc
		         (UnicodeCategory.DecimalDigitNumber   == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Nd
		         (UnicodeCategory.ConnectorPunctuation == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Pc
		         (UnicodeCategory.Format               == Char.GetUnicodeCategory(s, 1))     //UNICODE class Cf
		        );
	}

	public bool IsCombiningCharacter(string s)
	{
		return ( (UnicodeCategory.NonSpacingMark       == Char.GetUnicodeCategory(s, 1)) ||  //UNICODE class Mn
		         (UnicodeCategory.SpacingCombiningMark == Char.GetUnicodeCategory(s, 1))     //UNICODE class Mc
		        );
	}
	
}


//======================================
// Start of Lexer Rules
//======================================

PP_IDENT
	options { testLiterals = true; }
	:	( '_' 
		| LETTER_CHARACTER
		| { IsLetterCharacter(eseq.getText()) }? eseq:UNICODE_ESCAPE_SEQUENCE
		) 	     
		( LETTER_CHARACTER
		| DECIMAL_DIGIT_CHARACTER
		| CONNECTING_CHARACTER
		| COMBINING_CHARACTER
		| FORMATTING_CHARACTER
		| { IsIdentifierCharacter(eseq2.getText()) }? eseq2:UNICODE_ESCAPE_SEQUENCE
		)*
	;

PP_FILENAME
	:  '"'
	   ( ~( '"' | '\r' | '\n' | '\u2028' | '\u2029' ) )*
	   '"'
	;

PP_NUMBER
	:	(DECIMAL_DIGIT)+
	;

	
//======================================
// Section A.1.3 Comments
//
SL_COMMENT
	:	"//" ( NOT_NEWLINE )*
		// (NEWLINE)?
		//
		( 	('\r' ( options { generateAmbigWarnings=false; } : '\n' )?
			| '\n'
			| '\u2028'
			| '\u2029'
			)
			{ newline(); }
		)?
		{ selector_.pop(); }
	;

 //======================================
// Section A.1.1 Line terminators
//
NEWLINE
	:	( '\r' 									// MacOS-style newline
		  ( options { generateAmbigWarnings=false; } 
		    : '\n' 								// DOS/Windows style newline
		  )?
		| '\n'									// UNIX-style newline
		| '\u2028'								// UNICODE line separator
		| '\u2029'								// UNICODE paragraph separator
		)					
		{	newline();
			selector_.pop();
		}
	;


WHITESPACE
	:	(NON_NEWLINE_WHITESPACE)+
	;
	

