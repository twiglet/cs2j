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
/// A Lexer for the C# language including preprocessors directives.
/// </summary>
///
/// <remarks>
/// <para>
/// The Lexer defined below is based on the "C# Language Specification" as 
/// documented in the ECMA-334 standard dated December 2001.
/// </para>
///
/// <para>
/// The Lexer depends on the existence of two companion lexers to which it will 
/// delegate the handling of the rest of the contents of a line containing a C# 
/// preprocessor directives  after it has tokenized the directive itself. This 
/// companion lexers must be registered with the names "preproLexer" and 
/// "hooverLexer" in the <see cref="TokenStreamSelector"/> associated with this 
/// Lexer via the Selector property.
/// </para>
///
/// <para>
/// History
/// </para>
///
/// <para>
/// 31-May-2002 kunle	  Created first cut from ECMA spec (renamed from Ecma344_CSharp.g)         <br />
/// 08-Feb-2003 kunle     Separated Lexer from the original combined Lexer/Parser grammar file     <br />
/// 05-Apr-2004 kunle     Post-directive handling is now delegated to one of two companion lexers. <br />
/// </para>
///
/// </remarks>


*/
class CSharpLexer extends CSharpLexerBase;

options
{
	importVocab							= CSharpLexerBase;
	exportVocab							= CSharpLexer;
	charVocabulary						= '\u0000'..'\uFFFE';	// All UNICODE characters except \uFFFF [and \u0000 to \u0002 used by ANTLR]
	k									= 3;					// two characters of lookahead
	testLiterals						= false;   				// don't automatically test for literals
	//defaultErrorHandler				= true;
	defaultErrorHandler					= false;
	codeGenMakeSwitchThreshold 		= 5;  // Some optimizations
	codeGenBitsetTestThreshold		= 5;
}

//======================================
// Section A.1.7 Keywords
//
tokens										// MUST be kept in sync with "keywordsTable" Hashtable below!!
{
	ABSTRACT 		= "abstract";
	AS				= "as";
	BASE			= "base";
	BOOL			= "bool";
	BREAK			= "break";
	BYTE			= "byte";
	CASE			= "case";
	CATCH			= "catch";
	CHAR			= "char";
	CHECKED			= "checked";
	CLASS			= "class";
	CONST			= "const";
	CONTINUE		= "continue";
	DECIMAL			= "decimal";
//	DEFAULT			= "default";
	DELEGATE		= "delegate";
	DO				= "do";
	DOUBLE			= "double";
	ELSE			= "else";
	ENUM			= "enum";
	EVENT			= "event";
	EXPLICIT		= "explicit";
	EXTERN			= "extern";
//	FALSE			= "false";
	FINALLY			= "finally";
	FIXED			= "fixed";
	FLOAT			= "float";
	FOR				= "for";
	FOREACH			= "foreach";
	GOTO			= "goto";
	IF				= "if";
	IMPLICIT		= "implicit";
	IN				= "in";
	INT				= "int";
	INTERFACE		= "interface";
	INTERNAL		= "internal";
	IS				= "is";
	LOCK			= "lock";
	LONG			= "long";
	NAMESPACE		= "namespace";
	NEW				= "new";
	NULL			= "null";
	OBJECT			= "object";
	OPERATOR		= "operator";
	OUT				= "out";
	OVERRIDE		= "override";
	PARAMS			= "params";
	PRIVATE			= "private";
	PROTECTED		= "protected";
	PUBLIC			= "public";
	READONLY		= "readonly";
	REF				= "ref";
	RETURN			= "return";
	SBYTE			= "sbyte";
	SEALED			= "sealed";
	SHORT			= "short";
	SIZEOF			= "sizeof";
	STACKALLOC		= "stackalloc";
	STATIC			= "static";
	STRING			= "string";
	STRUCT			= "struct";
	SWITCH			= "switch";
	THIS			= "this";
	THROW			= "throw";
//	TRUE			= "true";
	TRY				= "try";
	TYPEOF			= "typeof";
	UINT			= "uint";
	ULONG			= "ulong";
	UNCHECKED		= "unchecked";
	UNSAFE			= "unsafe";
	USHORT			= "ushort";
	USING			= "using";
	VIRTUAL			= "virtual";
	VOID			= "void";
	VOLATILE		= "volatile";
	WHILE			= "while";

	DOT;
	UINT_LITERAL;
	LONG_LITERAL;
	ULONG_LITERAL;
	DECIMAL_LITERAL;
	FLOAT_LITERAL;
	DOUBLE_LITERAL;

	"add";
	"remove";
	"get";
	"set";
	"assembly";
	"field";
	"method";
	"module";
	"param";
	"property";
	"type";
}

{
	
	/// <summary>
	///   A <see cref="TokenStreamSelector"> for switching between this Lexer and the Preprocessor Lexer.
	/// </summary>
	private TokenStreamSelector selector_;
	
	/// <summary>
	///   A <see cref="TokenStreamSelector"> for switching between this Lexer and the Preprocessor Lexer.
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

	/// <summary>
	///   This table is used to keep a searchable list of keywords only. This is used mainly
	///   as for section "A.1.6 Identifers" for determining if an identifier is indeed a 
	///   VERBATIM_IDENTIFIER. It's contents MUST be kept in sync with the contents of section 
	///   "A.1.7 Keywords" above.
	/// </summary>
	///
	private static Hashtable keywordsTable = new Hashtable();
	
	static CSharpLexer()
	{
		keywordsTable.Add(ABSTRACT,  	"abstract");
		keywordsTable.Add(AS,        	"as");
		keywordsTable.Add(BASE,      	"base");
		keywordsTable.Add(BOOL,      	"bool");
		keywordsTable.Add(BREAK,     	"break");
		keywordsTable.Add(BYTE,      	"byte");
		keywordsTable.Add(CASE,      	"case");
		keywordsTable.Add(CATCH,     	"catch");
		keywordsTable.Add(CHAR,			"char");
		keywordsTable.Add(CHECKED,		"checked");
		keywordsTable.Add(CLASS,		"class");
		keywordsTable.Add(CONST,		"const");
		keywordsTable.Add(CONTINUE,		"continue");
		keywordsTable.Add(DECIMAL,		"decimal");
		keywordsTable.Add(DEFAULT,		"default");
		keywordsTable.Add(DELEGATE,		"delegate");
		keywordsTable.Add(DO,			"do");
		keywordsTable.Add(DOUBLE,		"double");
		keywordsTable.Add(ELSE,			"else");
		keywordsTable.Add(ENUM,			"enum");
		keywordsTable.Add(EVENT,		"event");
		keywordsTable.Add(EXPLICIT,		"explicit");
		keywordsTable.Add(EXTERN,		"extern");
		keywordsTable.Add(FALSE,		"false");
		keywordsTable.Add(FINALLY,		"finally");
		keywordsTable.Add(FIXED,		"fixed");
		keywordsTable.Add(FLOAT,		"float");
		keywordsTable.Add(FOR,			"for");
		keywordsTable.Add(FOREACH,		"foreach");
		keywordsTable.Add(GOTO,			"goto");
		keywordsTable.Add(IF,			"if");
		keywordsTable.Add(IMPLICIT,		"implicit");
		keywordsTable.Add(IN,			"in");
		keywordsTable.Add(INT,			"int");
		keywordsTable.Add(INTERFACE,	"interface");
		keywordsTable.Add(INTERNAL,		"internal");
		keywordsTable.Add(IS,			"is");
		keywordsTable.Add(LOCK,			"lock");
		keywordsTable.Add(LONG,			"long");
		keywordsTable.Add(NAMESPACE,	"namespace");
		keywordsTable.Add(NEW,			"new");
		keywordsTable.Add(NULL,			"null");
		keywordsTable.Add(OBJECT,		"object");
		keywordsTable.Add(OPERATOR,		"operator");
		keywordsTable.Add(OUT,			"out");
		keywordsTable.Add(OVERRIDE,		"override");
		keywordsTable.Add(PARAMS,		"params");
		keywordsTable.Add(PRIVATE,		"private");
		keywordsTable.Add(PROTECTED,	"protected");
		keywordsTable.Add(PUBLIC,		"public");
		keywordsTable.Add(READONLY,		"readonly");
		keywordsTable.Add(REF,			"ref");
		keywordsTable.Add(RETURN,		"return");
		keywordsTable.Add(SBYTE,		"sbyte");
		keywordsTable.Add(SEALED,		"sealed");
		keywordsTable.Add(SHORT,		"short");
		keywordsTable.Add(SIZEOF,		"sizeof");
		keywordsTable.Add(STACKALLOC,	"stackalloc");
		keywordsTable.Add(STATIC,		"static");
		keywordsTable.Add(STRING,		"string");
		keywordsTable.Add(STRUCT,		"struct");
		keywordsTable.Add(SWITCH,		"switch");
		keywordsTable.Add(THIS,			"this");
		keywordsTable.Add(THROW,		"throw");
		keywordsTable.Add(TRUE,			"true");
		keywordsTable.Add(TRY,			"try");
		keywordsTable.Add(TYPEOF,		"typeof");
		keywordsTable.Add(UINT,			"uint");
		keywordsTable.Add(ULONG,		"ulong");
		keywordsTable.Add(UNCHECKED,	"unchecked");
		keywordsTable.Add(UNSAFE,		"unsafe");
		keywordsTable.Add(USHORT,		"ushort");
		keywordsTable.Add(USING,		"using");
		keywordsTable.Add(VIRTUAL,		"virtual");
		keywordsTable.Add(VOID,			"void");
		keywordsTable.Add(WHILE,		"while");
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
		}
	;


//======================================
// Section A.1.2 White space
//

WHITESPACE
	:	pp1:PP_DIRECTIVE													
		{	if ( pp1.getColumn() == 1)
			{
				$setType(pp1.Type); 
				if ((pp1.Type == PP_REGION) || (pp1.Type == PP_ENDREGION) || (pp1.Type == PP_WARNING) || (pp1.Type == PP_ERROR))
					selector_.push("hooverLexer");
				else
					selector_.push("directivesLexer");
			}
			else
				$setType(PP_STRING); 
		} 
	|	nnw:NON_NEWLINE_WHITESPACE (NON_NEWLINE_WHITESPACE)*
		(	{ (nnw.getColumn() == 1) }? pp2:PP_DIRECTIVE 
			{	
				$setType(pp2.Type); 
				if ((pp2.Type == PP_REGION) || (pp2.Type == PP_ENDREGION) || (pp2.Type == PP_WARNING) || (pp2.Type == PP_ERROR))
					selector_.push("hooverLexer");
				else
					selector_.push("directivesLexer");
			}
		)?
	;
	
//======================================
// Section A.1.3 Comments
//
ML_COMMENT	
	:	"/*"
      ( options { generateAmbigWarnings=false; }		// ignore non-determinism on "*/" between me and block exit
        : { LA(2) != '/' }? '*'
      | NEWLINE					//{ newline(); }
      | ~( '*' | '\r' | '\n' | '\u2028' | '\u2029')		// ~( NEWLINE | '*' ) -- generated error
      )*
      "*/"                    //{ $setType(Token.SKIP); }
	;


//======================================
// A.1.6 Identifiers
//
IDENTIFIER
	options { testLiterals = true; }
	:  '@' '"'						{ $setType(STRING_LITERAL);  }
	   ( ~( '"' )
	   | ('"' '"')
	   )*
	   '"'
	|  ( '@' )?
	   (
		 ( '_' 
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
	   )
	;


//======================================
// A.1.8 Literals
//
//
INT_LITERAL		// BYTE, SHORT, INT, LONG
	:	'0' ('x' | 'X') (HEX_DIGIT)+
	 	(	('l' | 'L')							{ $setType(LONG_LITERAL); } 
	    	( ('u' | 'U')						{ $setType(ULONG_LITERAL); } )?
	  	| 	('u' | 'U')							{ $setType(UINT_LITERAL); }
	    	( ('l' | 'L')						{ $setType(ULONG_LITERAL); } )?
	  	)?
	| 	'.' 									{ $setType(DOT); }
      	(	(DECIMAL_DIGIT)+					{ $setType(DOUBLE_LITERAL); }
        	( ('e'|'E') ('+'|'-')? (DECIMAL_DIGIT)+ )?
        	(	( 'f' | 'F' )					{ $setType(FLOAT_LITERAL); }
	     	|	( 'd' | 'D' )
	     	|	( 'm' | 'M' )					{ $setType(DECIMAL_LITERAL); }
	     	)?
      	)?
	|	(DECIMAL_DIGIT)+
	  	(	'.' (DECIMAL_DIGIT)+				{ $setType(DOUBLE_LITERAL); }
      		( ('e'|'E') ('+'|'-')? (DECIMAL_DIGIT)+ )?
      		(	( 'f' | 'F' )					{ $setType(FLOAT_LITERAL); }
     		|	( 'd' | 'D' )
     		|	( 'm' | 'M' )					{ $setType(DECIMAL_LITERAL); }
     		)?
	  	|	('e'|'E') ('+'|'-')? 
	  		(DECIMAL_DIGIT)+					{ $setType(DOUBLE_LITERAL); }
      		(	( 'f' | 'F' )					{ $setType(FLOAT_LITERAL); }
     		|	( 'd' | 'D' )
     		|	( 'm' | 'M' )					{ $setType(DECIMAL_LITERAL); }
     		)?
	  	|	(	( 'f' | 'F' )					{ $setType(FLOAT_LITERAL); }
	    	|	( 'd' | 'D' )					{ $setType(DOUBLE_LITERAL); }
	    	|	( 'm' | 'M' )					{ $setType(DECIMAL_LITERAL); }
	    	)
     	|	(	('l' | 'L')						{ $setType(LONG_LITERAL); } 
	     		( ('u' | 'U') 					{ $setType(ULONG_LITERAL); } )?
	   		|	('u' | 'U')						{ $setType(UINT_LITERAL); }
	     		( ('l' | 'L')					{ $setType(ULONG_LITERAL); } )?
	   		)
     	)?
	;
	
CHAR_LITERAL
	:  '\''
		( ~( '\'' | '\\' | '\r' | '\n' | '\u2028' | '\u2029' )
		| ESCAPED_LITERAL
		)
		'\''
	;
	
STRING_LITERAL
	:  '"'
	   ( ~( '"' | '\\' | '\r' | '\n' | '\u2028' | '\u2029' )
	   | ESCAPED_LITERAL
	   )*
	   '"'
	;
	
	
// The ESCAPED_LITERAL rule represents a common subset of the definitons of both STRING_LITERAL
// and CHAR_LITERAL. It was extracted from both to ensure that multiples copies of the same
// [semi-complex] sub-recognizer isn't maintained in multiple places.
//
protected ESCAPED_LITERAL
	:  '\\'
		( '\''
		| '"'
		| '\\'
		| '0'
		| 'a'
		| 'b'
		| 'f'
		| 'n'
		| 'r'
		| 't'
		| 'v'
		| 'x' HEX_DIGIT 
		      ( options { generateAmbigWarnings=false; } 
		        : HEX_DIGIT 
		          ( options { generateAmbigWarnings=false; } 
		            : HEX_DIGIT 
		              ( options { generateAmbigWarnings=false; } 
		                : HEX_DIGIT
		              )? 
		          )? 
		      )?
		)		
	| UNICODE_ESCAPE_SEQUENCE
	;
	
	
//======================================
// A.1.9 Operators and punctuators
//
OPEN_CURLY		: '{'		;
CLOSE_CURLY		: '}'		;
OPEN_BRACK		: '['		;
CLOSE_BRACK		: ']'		;
OPEN_PAREN		: '('		;
CLOSE_PAREN		: ')'		;
//DOT			: '.'		;			// moved to INTEGER_LITERAL rule to avoid conflict
COMMA			: ','		;
COLON			: ':'		;
SEMI			: ';'		;
PLUS			: '+'		;
MINUS			: '-'		;
STAR			: '*'		;
DIV				: '/'		;
MOD				: '%'		;
BIN_AND			: '&'		;
BIN_OR			: '|'		;
BIN_XOR			: '^'		;
LOG_NOT			: '!'		;
BIN_NOT			: '~'		;
ASSIGN			: '='		;
LTHAN			: '<'		;
GTHAN			: '>'		;
QUESTION		: '?'		;
INC				: "++"		;
DEC				: "--"		;
LOG_AND			: "&&"		;
LOG_OR			: "||"		;
SHIFTL			: "<<"		;
SHIFTR			: ">>"		;
EQUAL			: "=="		;
NOT_EQUAL		: "!="		;
LTE				: "<="		;
GTE				: ">="		;
PLUS_ASSIGN		: "+="		;
MINUS_ASSIGN	: "-="		;
STAR_ASSIGN		: "*="		;
DIV_ASSIGN		: "/="		;
MOD_ASSIGN		: "%="		;
BIN_AND_ASSIGN	: "&="		;
BIN_OR_ASSIGN	: "|="		;
BIN_XOR_ASSIGN	: "^="		;
SHIFTL_ASSIGN	: "<<="		;
SHIFTR_ASSIGN	: ">>="		;
DEREF			: "->"		;


//======================================
// A.1.10 Pre-processing directives
//
	
protected PP_DIRECTIVE
	:	'#' (NON_NEWLINE_WHITESPACE)*
		(	"define"									{ $setType(PP_DEFINE);		}
		| 	"undef"										{ $setType(PP_UNDEFINE);	}
		|	"if"										{ $setType(PP_COND_IF);		}
		| 	"line"										{ $setType(PP_LINE);      	}
		|	"error"										{ $setType(PP_ERROR);     	}
		| 	"warning"									{ $setType(PP_WARNING);   	}
		| 	"region"									{ $setType(PP_REGION);    	}
		| 	'e'
			(	'l'
				(	"se"								{ $setType(PP_COND_ELSE);  	}
				| 	"if"								{ $setType(PP_COND_ELIF);  	}
				)
			|	"nd"
				( 	"if"								{ $setType(PP_COND_ENDIF); 	}
				|	"region"							{ $setType(PP_ENDREGION);  	}
				)
			)
		)
	;		

