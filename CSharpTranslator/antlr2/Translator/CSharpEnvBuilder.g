header
{
	using System.IO;
	using System.Text;
	using System.Collections;
	using ASTFrame						= antlr.debug.misc.ASTFrame;
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
/// An AST Printer (or un-parser) that prints the source code that a tree represents. 
/// </summary>
///
/// <remarks>
/// <para>
///	The default behaviour of this PrettyPrinter is to print out the AST and generate
/// source code that is as close to the original as is possible.
/// </para>
/// <para>
///	This behaviour can be overridden by supplying an <see cref="ICodeStyleScheme"/>
/// object that contains the settings for a custom formatting code style.
/// </para>
/// <para>
/// The TreeParser defined below is designed for the AST created by CSharpParser.
/// See the file "CSharpParser.g" for the details of that Parser.
/// </para>
///
/// <para>
/// History
/// </para>
///
/// <para>
/// 05-Jun-2003 kunle	  Created file.
/// </para>
///
/// </remarks>


*/


/* keving:
** 
** Notes
** 
*/
class CSharpEnvBuilder extends TreeParser("RusticiSoftware.Translator.JavaTreeParser");

options
{
	importVocab						= CSharpJava;
	ASTLabelType					= "ASTNode";
	defaultErrorHandler				= true;
}

//=============================================================================
// Start of CODE
//=============================================================================

{
	private DirectoryHT appEnv = null;
	private string nameSpace = "";
	
	
	private bool NotExcluded(CodeMaskEnums codeMask, CodeMaskEnums construct)
	{
		return ((codeMask & construct) != 0 );
	}
	
	
}

//=============================================================================
// Start of RULES
//=============================================================================


// A C# compilation unit is a file containing a mixture of namespaces, classes,
// instances, structs, etc. We do some jiggery pokery here to convert this to a list
// of Java compilation units, each of which contains appropriate package names, imports,
// and a single class / instance declaration.  Each of these Java compilation units will be
// written out to a separate java source file by the driver program.  
compilationUnit [SigEnv e, DirectoryHT envIn]
 { appEnv = envIn;
	usePath = new Stack();
 	usePath.Push(new ArrayList()); 
 }
	:	#(	COMPILATION_UNIT
			justPreprocessorDirectives[e]
			uses:usingDirectives[e]
			globalAttributes[e]
			cus:namespaceMemberDeclarations[e]
		)
	;
	
usingDirectives [SigEnv e]
	:	#(	USING_DIRECTIVES
			(	preprocessorDirective[e, CodeMaskEnums.UsingDirectives]
			|	usingDirective[e] 
			)*
		) 
	;
	
usingDirective [SigEnv e]
	:	#( USING_NAMESPACE_DIRECTIVE 	
			id:qualifiedIdentifier[e] 		{ ((ArrayList)usePath.Peek()).Add(idToString(#id)); }	
		) 
	|	#(	USING_ALIAS_DIRECTIVE     	
			alias:identifier[e] 					
			aid:qualifiedIdentifier[e] 		{ ((ArrayList)usePath.Peek()).Add(idToString(#alias) + "=" + idToString(#aid)); }	
		)
	;

namespaceMemberDeclarations [SigEnv e]
  {  string saveNameSpace = nameSpace; }
	:	(	namespaceMemberDeclaration[e]   { nameSpace = saveNameSpace; }
		|	preprocessorDirective[e, CodeMaskEnums.NamespaceMemberDeclarations] { nameSpace = saveNameSpace; }
		)* 
	;
	
namespaceMemberDeclaration [SigEnv e]
	:	namespaceDeclaration[e]
	|	typeDeclaration[e]
	;
	
typeDeclaration [SigEnv e]
		:	cla:classDeclaration[e]
		|	str:structDeclaration[e]
		|	iface:interfaceDeclaration[e]		
		|	enm:enumDeclaration[e]
		|	delegateDeclaration[e]	
	;

namespaceDeclaration [SigEnv e]
	:	#(  NAMESPACE  
			m_ns:qualifiedIdentifier[e] { nameSpace += idToString(#m_ns) + ".";
										  usePath.Push(new ArrayList()); 
										  ((ArrayList)usePath.Peek()).Add(idToString(#m_ns)); 
										} 
			bdy:namespaceBody[e] { usePath.Pop(); }
		)
	;
	
namespaceBody [SigEnv e]
	:	#( NAMESPACE_BODY usingDirectives[e] namespaceMemberDeclarations[e] CLOSE_CURLY    
		)
	;
	
classModifiers [SigEnv e]
	:	modifiers[e]			// indirection for any special processing
	;
		
modifiers [SigEnv e] // TODO: If there are no access modifiers then make it private (check)
	:	#( MODIFIERS ( modifier[e] )* )
	;

modifier [SigEnv e]
	:	( ABSTRACT				
		|/*nw:*/NEW			
		|/*ov:*/OVERRIDE		
		| PUBLIC				
		| PROTECTED				
		| INTERNAL		 		
		| PRIVATE				
		| SEALED       
		|/*st:*/STATIC		
		|/*vi:*/VIRTUAL		
		|/*ext:*/EXTERN		
		| READONLY		
		|/*un:*/UNSAFE		
		|/*vo:*/VOLATILE		
		)
	;


typeName [SigEnv e]
	:	predefinedType[e]
	|	qualifiedIdentifier[e]
	;
	
classTypeName [SigEnv e]
	:	qualifiedIdentifier[e]
	|   OBJECT    		
	|/*str:*/STRING			
	;
	
identifier [SigEnv e]
	: IDENTIFIER		
	;
	
qualifiedIdentifier [SigEnv e]
	:	(	identifier[e]
		|	#(DOT identifier[e]	qualifiedIdentifier[e] )
		) 
	;

	
//
// A.2.2 Types
//

type [SigEnv e] returns [string t]
  { string rs = ""; t = null; }
	:	#(	TYPE 
			( 	id:qualifiedIdentifier[e]     { t = idToString(#id); }
			| 	t = predefinedType[e]
			|   VOID						  { t = "System.Void"; }
			)
			pointerSpecifier[e] 
			rs = rankSpecifiers[e]			
		)
		{ t += rs; }
	;
	
pointerSpecifier [SigEnv e]
	:	#(	STARS 
			( STAR 
			)* 
		)
	;
	
classType [SigEnv e]
	:	qualifiedIdentifier[e]
	|  OBJECT  			
	|/*str:*/STRING			
	;
	
interfaceType [SigEnv e]
	:	qualifiedIdentifier[e]
	;

delegateType [SigEnv e]
	:	qualifiedIdentifier[e]		// typeName
	;

/*	
pointerType
	:	unmanagedType STAR
	|	VOID STAR
	;
*/	
unmanagedType [SigEnv e]
	:	qualifiedIdentifier[e]		// typeName
	;
	
//
// A.2.3 Variables
//

variableReference [SigEnv e]
	:	expression[e]
	;

//
// A.2.4 Expressions
//
	
argumentList [SigEnv e]  // Simplify by making it an EXPR_LIST
	:	#(	ARG_LIST ( argument[e] )+
		)
	;
	
argument [SigEnv e]
	:	expression[e]
	|	#(/*r:*/REF variableReference[e] )
	|	#(/*o:*/OUT variableReference[e] )
	;

constantExpression [SigEnv e]
	:	expression[e]
	;
	
booleanExpression [SigEnv e]
	:	expression[e]
	;
	
expressionList [SigEnv e]
	:	#(	EXPR_LIST ( expression[e] )+
		)
	;

expression [SigEnv e]
	:	#( EXPR expr[e] )
	;
	
expr [SigEnv e]
		// assignmentExpression
		//
	:	#( ASSIGN         expr[e]  expr[e] )
	|	#( PLUS_ASSIGN    expr[e]  expr[e] )
	|	#( MINUS_ASSIGN   expr[e]  expr[e] )
	|	#( STAR_ASSIGN    expr[e]  expr[e] )
	|	#( DIV_ASSIGN     expr[e]  expr[e] )
	|	#( MOD_ASSIGN     expr[e]  expr[e] )
	|	#( BIN_AND_ASSIGN expr[e]  expr[e] )
	|	#( BIN_OR_ASSIGN  expr[e]  expr[e] )
	|	#( BIN_XOR_ASSIGN expr[e]  expr[e] )
	|	#( SHIFTL_ASSIGN  expr[e]  expr[e] )
	|	#( SHIFTR_ASSIGN  expr[e]  expr[e] )
		// conditionalExpression
		//
	|	#( QUESTION       expr[e]  expr[e]  expr[e] )
	
		// conditional-XXX-Expressions
		//
	|	#( LOG_OR         expr[e]  expr[e] )
	|	#( LOG_AND        expr[e]  expr[e] )
		
		// bitwise-XXX-Expressions
		//
	|	#( BIN_OR         expr[e]  expr[e] )
	|	#( BIN_XOR        expr[e]  expr[e] )
	|	#( BIN_AND        expr[e]  expr[e] )

		// equalityExpression
		//
	|	#( EQUAL          expr[e]  expr[e] )
	|	#( NOT_EQUAL      expr[e]  expr[e] )

		// relationalExpression
		//
	|	#( LTHAN          expr[e]  expr[e] )
	|	#( GTHAN          expr[e]  expr[e] )
	|	#( LTE            expr[e]  expr[e] )
	|	#( GTE            expr[e]  expr[e] )
	|	#( IS             expr[e]  type[e] )
	|	#( AS             expr[e]  type[e] ) 
	
		// shiftExpression
		//
	|	#( SHIFTL         expr[e]  expr[e] )
	|	#( SHIFTR         expr[e]  expr[e] )

		// additiveExpression
		//
	|	#( PLUS           expr[e]  expr[e] )
	|	#( MINUS          expr[e]  expr[e] )
		// multiplicativeExpression
		//
	|	#( STAR           expr[e]  expr[e] )
	|	#( DIV            expr[e]  expr[e] )
	|	#( MOD            expr[e]  expr[e] )
	|	unaryExpression[e]
	;	

unaryExpression [SigEnv e]
	:	#( CAST_EXPR 			 type[e] expr[e] )
	|	#( INC              	 expr[e] )
	|	#( DEC              	 expr[e] )
	|	#( UNARY_PLUS       	 expr[e] )
	|	#( UNARY_MINUS      	 expr[e] )
	|	#( LOG_NOT             expr[e] )
	|	#( BIN_NOT			 expr[e] )
	|	#(/*p:*/PTR_INDIRECTION_EXPR  expr[e] )
	|	#(/*a:*/ADDRESS_OF_EXPR       expr[e] )
	|	primaryExpression[e]
	;
	
primaryExpression [SigEnv e]
	:	#(	// invocationExpression ::= primaryExpression OPEN_PAREN ( argumentList )? CLOSE_PAREN 
			INVOCATION_EXPR			primaryExpression[e] 
									(a:argumentList[e])?   
		)
	|	#(	// elementAccess		::= primaryNoArrayCreationExpression OPEN_BRACK expressionList CLOSE_BRACK
		/*e:*/ELEMENT_ACCESS_EXPR		primaryExpression[e] 
										expressionList[e]    
		)
	|	#(	// pointerElementAccess ::= primaryNoArrayCreationExpression OPEN_BRACK expression     CLOSE_BRACK
		/*p:*/PTR_ELEMENT_ACCESS_EXPR	primaryExpression[e]  
										expressionList[e]    
		)
	|	#(	// memberAccess		    ::= primaryExpression DOT identifier
		    MEMBER_ACCESS_EXPR      									
			(	type[e]
			|	primaryExpression[e]
			)
			identifier[e]
		)
	|	// pointerMemberAccess
		#(/*d:*/DEREF                   primaryExpression[e]  identifier[e] )
	|	// postIncrementExpression
		#( POST_INC_EXPR          primaryExpression[e]  )
	|	// postDecrementExpression
		#( POST_DEC_EXPR          primaryExpression[e]  )
	|	basicPrimaryExpression[e]
	;

basicPrimaryExpression [SigEnv e]
	:	literal[e]
	|	identifier[e]										// simpleName
	|	// parenthesizedExpression
		//
		#( PAREN_EXPR  expr[e]  )   
	| THIS 		
	|	#( BASE		
			(	i:identifier[e]   
			|	expressionList[e]  // TODO:access to base class indexer ... 
			)
		) 
	|	newExpression[e]
	|	// typeofExpression    
		//
		#( TYPEOF 	 type[e] )   
	|	#(/*s:*/SIZEOF    	 unmanagedType[e]  )
	|	#(/*c:*/CHECKED   	 ce:expression[e]  )      
	|	#(/*u:*/UNCHECKED 	 ue:expression[e]  )    
	;

newExpression [SigEnv e]
		// objectCreationExpression	  
		//
	:	#(OBJ_CREATE_EXPR  type[e]  (argumentList[e])?  )  
		// delegateCreationExpression	  
		//
	|	#(/*dl:*/DLG_CREATE_EXPR  type[e]  argumentList[e]  )
		// arrayCreationExpression
		//
	|	#( ARRAY_CREATE_EXPR 
			type[e]										// nonArrayType ( rankSpecifiers )?
			(	 arrayInitializer[e]
			|	 expressionList[e]  
				 rankSpecifiers[e] ( arrayInitializer[e] )? 
			)
		)
	;

literal [SigEnv e]
	: TRUE				
	| FALSE			
	| INT_LITERAL		
	| UINT_LITERAL		
	| LONG_LITERAL		
	| ULONG_LITERAL	
	| DECIMAL_LITERAL	
	| FLOAT_LITERAL	
	| DOUBLE_LITERAL	
	| CHAR_LITERAL		
	| STRING_LITERAL	
	| NULL				
	;

predefinedType [SigEnv e] returns [string t]
  { t = null; }
	: BOOL				{ t = "System.Boolean"; }  		 
	| BYTE		  		{ t = "System.Byte"; }  	
	| CHAR				{ t = "System.Char"; }  	
	| DECIMAL	  		{ t = "System.Decimal"; }  	
	| DOUBLE			{ t = "System.Double"; }  	
	| FLOAT				{ t = "System.Single"; }  	
	| INT				{ t = "System.Int32"; }  	
	| LONG				{ t = "System.Int64"; }  	
	| OBJECT			{ t = "System.Object"; }  	
	| SBYTE				{ t = "System.SByte"; }  	
	| SHORT				{ t = "System.Int16"; }  	
	| STRING	 		{ t = "System.String"; }  	
	| UINT				{ t = "System.UInt32"; }  	
	| ULONG				{ t = "System.UInt64"; }  	
	| USHORT			{ t = "System.UInt16"; }  	
	;
	

//
// A.2.5 Statements
//

statement [SigEnv e]
	:	#(LABEL_STMT identifier[e]  statement[e]
		)
	|	localVariableDeclaration[e] 
	|	localConstantDeclaration[e]
	|	embeddedStatement[e]
	|	preprocessorDirective[e, CodeMaskEnums.Statements]
	;
	
embeddedStatement [SigEnv e]
	:	block[e]
	|/*emp:*/EMPTY_STMT	
	|	#(/*sxp:*/EXPR_STMT statementExpression[e]  )
	|	#(IF 
			 expression[e]  embeddedStatement[e]
			(	#(ELSE 
					embeddedStatement[e]
				)
			)? 
		)
	|	
	    #(   SWITCH 
			 se:expression[e] 
			#( OPEN_CURLY 
				( ss:switchSection[e] )* 
			 CLOSE_CURLY 
			) 
		) 
	|	#( FOR 
			#( FOR_INIT ( ( localVariableDeclaration[e] | ( statementExpression[e] )+ ) )? )
			
			#( FOR_COND ( booleanExpression[e] )? )
			
			#( FOR_ITER ( ( statementExpression[e] )+  )? )
			
			embeddedStatement[e]
		)
	|	#(/*whileStmt:*/WHILE 
			booleanExpression[e]  embeddedStatement[e]
		)
	|	#(/*doStmt:*/DO 
			embeddedStatement[e]  booleanExpression[e] 
		)
	|	#(/*foreachStmt:*/FOREACH 
			localVariableDeclaration[e]  expression[e] 
			
			embeddedStatement[e]
		)
	|/*brk:*/BREAK		
	|/*ctn:*/CONTINUE	
	|	#(/*gto:*/GOTO 	
			(	identifier[e] 
			|/*cse:*/CASE 	 constantExpression[e]
			|/*dfl:*/DEFAULT	
			)
			
		)
	|	#(/*rtn:*/RETURN  ( expression[e] )?  )
	|	#(/*trw:*/THROW   ( expression[e] )?  )
	|	tryStatement[e]
	|	#(/*checkedStmt:*/CHECKED 	   block[e]
		)
	|	#(/**/UNCHECKED	   block[e]
		)
	|	#(/*lockStmt:*/LOCK 
			 expression[e]  embeddedStatement[e]
		)
	|	#(/*usingStmt:*/USING 
			 resourceAcquisition[e]  embeddedStatement[e]
	)	
	|	#(/*unsafeStmt:*/UNSAFE 
			block[e]
		)
	|	// fixedStatement
		#(/*fixedStmt:*/FIXED 
			 type[e] 
			fixedPointerDeclarator[e] (  fixedPointerDeclarator[e] )*
			
			embeddedStatement[e]
		)
	;
	
body [SigEnv e]
	:	block[e]
	|   EMPTY_STMT
	;

block [SigEnv e]
	:	#(BLOCK 
			( statement[e] )*
		 CLOSE_CURLY 
		)
	;
	
statementList[SigEnv e]
	:	#( STMT_LIST ( statement[e] )+ )
	;
	
localVariableDeclaration [SigEnv e]
	:	#(	LOCVAR_DECLS t:type[e] 
			(d:localVariableDeclarator[e]  )+ 
			) 
	;
	
localVariableDeclarator [SigEnv e]
	:	#(	VAR_DECLARATOR identifier[e] (localVariableInit[e])?	
		)
	;

localVariableInit [SigEnv e]
	:
		#(	LOCVAR_INIT
			(	expression[e]
			|	arrayInitializer[e]
			)
		) 
	;
	
		
localConstantDeclaration [SigEnv e] 
	:	#(LOCAL_CONST  t:type[e] 
			( d:constantDeclarator[e] )+
		)
	;
	
constantDeclarator [SigEnv e] returns [string i]
  { i = ""; }
	:	#(CONST_DECLARATOR id:identifier[e] { i = idToString(#id); } constantExpression[e] ) 
	;
	
statementExpression [SigEnv e]
	:	expr[e] 
	;
	
switchSection[SigEnv e]
	:	#( SWITCH_SECTION switchLabels[e] statementList[e] )
	;
	
switchLabels [SigEnv e]
	:	#(	SWITCH_LABELS 
			(	(	#(CASE  expression[e] )
				|  DEFAULT	
				)
				
			)+ 
		) 
	;
	
tryStatement [SigEnv e]
	:	#( TRY 
			block[e]
			(	finallyClause[e]
			|	catchClauses[e] ( finallyClause[e] )?
			)
		)
	;
	
catchClauses [SigEnv e]
	:	(	
			catchClause[e]
		)+
	;
	
catchClause [SigEnv e]
	: #( CATCH b:block[e] 
			(	t:type[e]						
			|	l:localVariableDeclaration[e]	
			)*
		) 
	;
	
finallyClause [SigEnv e]
	:	#( FINALLY 
			block[e]
		)
	;
	
resourceAcquisition[SigEnv e]
	:	localVariableDeclaration[e]
	|	expression[e]
	;
	
//	
// A.2.6 Classes
//

classDeclaration [SigEnv e]
  { string[] ts = null; 
    ClassRepTemplate cla = null;
    SigEnv env = new SigEnv(); 
    string saveNameSpace = nameSpace;
  }
	:	#( CLASS
			attributes[e]  
			mod:classModifiers[e]  
			id:identifier[e]    
			ts = classBase[e] 
			{ usePath.Push(new ArrayList()); 
			  ((ArrayList)usePath.Peek()).Add(nameSpace + idToString(#id)); 
			  nameSpace += idToString(#id) + "."; }
			#(TYPE_BODY  classMemberDeclarations[env] CLOSE_CURLY ) 
			{ 
			   nameSpace = saveNameSpace;
			   cla = new ClassRepTemplate(nameSpace + #id.getText(), CollectUsePath(), ts, 
										  (ConstructorRepTemplate[]) env.Constructors.ToArray(typeof(ConstructorRepTemplate)),
										  (MethodRepTemplate[]) env.Methods.ToArray(typeof(MethodRepTemplate)),
										  (PropRepTemplate[]) env.Properties.ToArray(typeof(PropRepTemplate)),
										  (FieldRepTemplate[]) env.Fields.ToArray(typeof(FieldRepTemplate)),
										  (CastRepTemplate[]) env.Casts.ToArray(typeof(CastRepTemplate)),
										  new string[0], null
										  );
			   appEnv[nameSpace + #id.getText()] = cla; 
			   usePath.Pop();
			} 
		)
	;
	
classBase [SigEnv e] returns [string[] ts]
  { ArrayList tempBs = new ArrayList();
    string t = "";
    ts = null;
  }
	: #( CLASS_BASE ( t=type[e]  { tempBs.Add(t); }  )* )
		{ ts = (string[]) tempBs.ToArray(typeof(string)); }
	;
	
classMemberDeclarations [SigEnv e]
	:	#(	MEMBER_LIST
			(	classMemberDeclaration [e]
			|	preprocessorDirective[e, CodeMaskEnums.ClassMemberDeclarations]
			)*
		)
	;
	
classMemberDeclaration [SigEnv e]
	:	(	destructorDeclaration[e]
		|	typeMemberDeclaration[e]
		)
	;
	
typeMemberDeclaration [SigEnv e]
	:	(	constantDeclaration[e]
		|	eventDeclaration[e]
		|	constructorDeclaration[e]
		|	staticConstructorDeclaration[e]
		|	propertyDeclaration[e]
		|	methodDeclaration[e]
		|	indexerDeclaration[e]
		|	fieldDeclaration[e]
		|	operatorDeclaration[e]
		|	typeDeclaration[e]
		)
	;
	
constantDeclaration [SigEnv e]
  { string t; string i; }
	:	#( CONST attributes[e] m:modifiers[e] t = type[e] ( i = constantDeclarator[e] { e.Fields.Add(new FieldRepTemplate(t,i)); } )+ )
	;
	
fieldDeclaration [SigEnv e]
  { string t; string i; }
	:	#(	FIELD_DECL attributes[e] modifiers[e] t = type[e]
			( i = variableDeclarator[e] { e.Fields.Add(new FieldRepTemplate(t,i)); } )+
			
		)
	;
	
variableDeclarator [SigEnv e] returns [string i]
  { i = ""; }
	:	#(	VAR_DECLARATOR id:identifier[e] { i = idToString(#id); }
			( variableInitializer[e] )? 
		)
	;
	
variableInitializer [SigEnv e]
	:	#(	VAR_INIT
			(	expression[e]
			|	arrayInitializer[e]
			|	stackallocInitializer[e]
			)
		)
	;
		
methodDeclaration [SigEnv e]
  { string i = "";
    string rt = "";
    ParamRepTemplate[] pts = new ParamRepTemplate[0];
  }
	:	#(	METHOD_DECL a:attributes[e] m:modifiers[e] rt = type[e] id:qualifiedIdentifier[e] { i = idToString(#id); }
			b:methodBody[e]
			 ( pts = formalParameterList[e] )? 
		) { if (i == "ToString" && pts.Length == 0) 
		       i = "toString";
		    e.Methods.Add(new MethodRepTemplate(rt,i,pts)); }
	;
	
memberName [SigEnv e]
	:	qualifiedIdentifier[e]					// interfaceType^ DOT identifier
//	|	identifier
	;
	
methodBody [SigEnv e]
	:	body[e]
	;
	
formalParameterList [SigEnv e] returns [ParamRepTemplate[] ps]
  { ArrayList atys = new ArrayList();
    ArrayList ftys = new ArrayList();
    ParamRepTemplate pt = null;
    ps = new ParamRepTemplate[0];
  }
	:	#(	FORMAL_PARAMETER_LIST 
			(	ftys = fixedParameters[e] { atys = ftys; } (  pt = parameterArray[e] { atys.Add(pt); } )?
			|	pt = parameterArray[e]  { atys.Add(pt); }
			) { ps = (ParamRepTemplate[]) atys.ToArray(typeof(ParamRepTemplate)); }
		)
	;
	
fixedParameters [SigEnv e] returns [ArrayList ps]
  { ps = new ArrayList();
    ParamRepTemplate p = null; 
  }
	: (  p=fixedParameter[e]  { ps.Add(p); } )+
	;
	
fixedParameter [SigEnv e] returns [ParamRepTemplate p]
  {  string t = "";
     string i = "";
     p = null;
  }
	:	#( 	PARAMETER_FIXED attributes[e] 
			t = type[e] id:identifier[e] { i = idToString(#id); } 
			( parameterModifier[e] )?
		)  { p = new ParamRepTemplate(t,i); }
	;
	
parameterModifier [SigEnv e]
	: REF		
	| OUT		
	;
	
parameterArray [SigEnv e] returns [ParamRepTemplate p]
  { string t = "";
    string i = "";
    p = null;
  }
	:	#(PARAMS attributes[e]  t = type[e] id:identifier[e] { i = idToString(#id); } 
		) { p = new ParamRepTemplate(t + "[]",i); }
	;
	
propertyDeclaration [SigEnv e]
  { string t; }
	:	#(	PROPERTY_DECL attributes[e] m:modifiers[e] t = type[e] id:qualifiedIdentifier[e] 
			a:accessorDeclarations[e] CLOSE_CURLY 
		)
		{ e.Properties.Add(new PropRepTemplate(t, #id.getText())); }     
	;
	
accessorDeclarations [SigEnv e]
	:	(	accessorDeclaration[e]
		)*
	;
	
accessorDeclaration [SigEnv e]
	:	#( "get" attributes[e] accessorBody[e] )
	|   #( "set" attributes[e] accessorBody[e] )
	;
	
	
accessorBody [SigEnv e]
	:	block[e]
	|   EMPTY_STMT
	;
	
eventDeclaration [SigEnv e]
	:	#(/*evt:*/EVENT attributes[e] modifiers[e]  type[e]
			(	qualifiedIdentifier[e] 
				eventAccessorDeclarations[e]/*cly:*/CLOSE_CURLY 
			|	variableDeclarator[e] (  variableDeclarator[e] )* 
				
			)
		)
	;
	
eventAccessorDeclarations [SigEnv e]
	:	addAccessorDeclaration[e] removeAccessorDeclaration[e]
	|	removeAccessorDeclaration[e] addAccessorDeclaration[e]
	;
	
addAccessorDeclaration [SigEnv e]
	:	#( "add"    attributes[e] block[e] )
	;
	
removeAccessorDeclaration [SigEnv e]
	:	#( "remove" attributes[e] block[e] )
	;

indexerDeclaration [SigEnv e]
	:	#(	INDEXER_DECL attributes[e] modifiers[e]
			type[e] ( interfaceType[e]  )?/*t:*/THIS
			formalParameterList[e]  accessorDeclarations[e] 
		/*cly:*/CLOSE_CURLY
		)
	;
	
operatorDeclaration [SigEnv e]
  { string t = "";
    ParamRepTemplate[] ps = null;
  }
	:	(	#(	UNARY_OP_DECL attributes[e] modifiers[e]
				type[e]  overloadableUnaryOperator[e]
				 formalParameterList[e]  
	 			operatorBody[e]
		 	)
		|	#(	BINARY_OP_DECL attributes[e] modifiers[e]
				type[e]  overloadableBinaryOperator[e]
				 formalParameterList[e] 
		 		operatorBody[e]
			 )
		|	#(	CONV_OP_DECL attributes[e] modifiers[e]
				(IMPLICIT | EXPLICIT) t=type[e]
					ps=formalParameterList[e] 
					operatorBody[e]
			)  {
			       e.Casts.Add(new CastRepTemplate(ps[0].Type, t));  
			   }
		)
	;
	
overloadableUnaryOperator [SigEnv e]
	:  UNARY_PLUS	
	|  UNARY_MINUS	
	|  LOG_NOT		
	|  BIN_NOT		
	|  INC			
	|  DEC			
	|  TRUE			
	|  FALSE		
	;
	
overloadableBinaryOperator [SigEnv e]
	:/*pl:*/PLUS			
	|/*ms:*/MINUS		
	|/*st:*/STAR			
	|/*dv:*/DIV 			
	|/*md:*/MOD 			
	|/*ba:*/BIN_AND 		
	|/*bo:*/BIN_OR 		
	|/*bx:*/BIN_XOR 		
	|/*sl:*/SHIFTL 		
	|/*sr:*/SHIFTR 		
	|/*eq:*/EQUAL		
	|/*nq:*/NOT_EQUAL 	
	|/*gt:*/GTHAN		
	|/*lt:*/LTHAN 		
	|/*ge:*/GTE 			
	|/*le:*/LTE 			
	;
	
operatorBody [SigEnv e]
	:	body[e]
	;

constructorDeclaration [SigEnv e]
  { ParamRepTemplate[] pts = new ParamRepTemplate[0]; }
	:	#(	CTOR_DECL attributes[e] modifiers[e] identifier[e]
			constructorBody[e]
			( pts = formalParameterList[e] )? 
			( c:constructorInitializer[e] )? 
		) { e.Constructors.Add(new ConstructorRepTemplate(pts)); }
	;
	
constructorInitializer [SigEnv e]
	:	(	#( BASE  ( argumentList[e] )? ) 
		|	#( THIS  ( argumentList[e] )? )
		)
	;
	
constructorBody [SigEnv e]
	:	body[e]
	;

staticConstructorDeclaration [SigEnv e]
	:	#(	STATIC_CTOR_DECL attributes[e] modifiers[e] identifier[e] 
			staticConstructorBody[e]
		)
	;
	
staticConstructorBody [SigEnv e]
	:	body[e]
	;
	
destructorDeclaration [SigEnv e]
	:	#( 	DTOR_DECL attributes[e] modifiers[e] identifier[e] 
			destructorBody[e]
		)
	;
	
destructorBody [SigEnv e]
	:	body[e]
	;

	
//
// A.2.7 Structs
//


// Convert to a class
structDeclaration [SigEnv e]
  { string[] ts = null; 
    StructRepTemplate str = null;
    SigEnv env = new SigEnv(); 
    string saveNameSpace = nameSpace;
  }	:	#( STRUCT 
				attributes[e] 
				mod:modifiers[e] 
				id:identifier[e] 
			    ts = structImplements[e]
			    { usePath.Push(new ArrayList()); 
			      ((ArrayList)usePath.Peek()).Add(nameSpace + idToString(#id)); 
			      nameSpace += idToString(#id) + "."; }
			#( TYPE_BODY mem:structMemberDeclarations[env] CLOSE_CURLY  )
			{ 
			   nameSpace = saveNameSpace;
			   str = new StructRepTemplate(nameSpace + #id.getText(), CollectUsePath(), ts, 
										  (ConstructorRepTemplate[]) env.Constructors.ToArray(typeof(ConstructorRepTemplate)),
										  (MethodRepTemplate[]) env.Methods.ToArray(typeof(MethodRepTemplate)),
										  (PropRepTemplate[]) env.Properties.ToArray(typeof(PropRepTemplate)),
										  (FieldRepTemplate[]) env.Fields.ToArray(typeof(FieldRepTemplate)),
										  (CastRepTemplate[]) env.Casts.ToArray(typeof(CastRepTemplate)),
										  new string[0], null
										  );
			   appEnv[nameSpace + #id.getText()] = str; 
			   usePath.Pop();
			} 
		) 
	;

structImplements [SigEnv e] returns [string[] ts]
   { ArrayList tempIs = new ArrayList();
     String t;
     ts = null;
   }     
	:	#( STRUCT_BASE ( t=type[e] { tempIs.Add(t); } )* ) 
	    { ts = (string[]) tempIs.ToArray(typeof(string)); }
	;	
	
structMemberDeclarations [SigEnv e]
		// Add Default Constructor
	: #(	MEMBER_LIST
			(	s:structMemberDeclaration[e] 
			|	p:preprocessorDirective[e, CodeMaskEnums.StructMemberDeclarations] 
			)*
		) 
	;
	
structMemberDeclaration [SigEnv e]
	:	typeMemberDeclaration[e]
	;

	
//
// A.2.8 Arrays
//

rankSpecifiers [SigEnv e] returns [string rs]
  { string r = ""; rs = ""; }
	:	#(	ARRAY_RANKS
			( 	r = rankSpecifier[e] { rs += r; }
			)*
		)
	;
	
rankSpecifier  [SigEnv e] returns [string r]
  { r = "["; }
	:	#( ARRAY_RANK 
			(COMMA  { r += ","; }
			)* 			
		) { r += "]"; }
	;
	
arrayInitializer [SigEnv e]
	:	#( ARRAY_INIT  ( variableInitializerList[e] )? CLOSE_CURLY  ) 
	;
	
variableInitializerList [SigEnv e]
	:	#( VAR_INIT_LIST v:arrayvariableInitializer[e] ( arrayvariableInitializer[e] )* )
	;

arrayvariableInitializer [SigEnv e]
	:	v:variableInitializer[e] 
	;

// 
// A.2.9 Interfaces
//

interfaceDeclaration [SigEnv e]
  { string[] ts = null; 
    InterfaceRepTemplate inter = null;
    SigEnv env = new SigEnv(); 
    string saveNameSpace = nameSpace;
  }	:	#(INTERFACE attributes[e] mod:modifiers[e] id:identifier[e] 
			ts = interfaceImplements[e]
			{ usePath.Push(new ArrayList()); 
			  ((ArrayList)usePath.Peek()).Add(nameSpace + idToString(#id)); 
			  nameSpace += idToString(#id) + "."; }
			#( TYPE_BODY mem:interfaceMemberDeclarations[env] CLOSE_CURLY  )
			{ 
			   nameSpace = saveNameSpace;
			   inter = new InterfaceRepTemplate(nameSpace + #id.getText(), CollectUsePath(), ts, 
										  (MethodRepTemplate[]) env.Methods.ToArray(typeof(MethodRepTemplate)),
										  (PropRepTemplate[]) env.Properties.ToArray(typeof(PropRepTemplate)),
										  (FieldRepTemplate[]) env.Fields.ToArray(typeof(FieldRepTemplate)),
										  (CastRepTemplate[]) env.Casts.ToArray(typeof(CastRepTemplate)),
										  new string[0], null
										  );
			   appEnv[nameSpace + #id.getText()] = inter;
			   usePath.Pop(); 
			} 
			
		) 
	;
	
interfaceImplements [SigEnv e] returns [string[] ts]
  { ArrayList tempBs = new ArrayList();
    string t = "";
    ts = null;
  }
    : #( INTERFACE_BASE ( t=type[e] { tempBs.Add(t); } )* )
		{ ts = (string[]) tempBs.ToArray(typeof(string)); }    
	;
	
interfaceMemberDeclarations [SigEnv e]
	:	#(	MEMBER_LIST
			(	interfaceMemberDeclaration[e]
			|	preprocessorDirective[e, CodeMaskEnums.InterfaceMemberDeclarations]
			)*
		)
	;
	
interfaceMemberDeclaration [SigEnv e]
	:	(	methodDeclaration[e]
		|	propertyDeclaration[e]
		|	eventDeclaration[e]
		|	indexerDeclaration[e]
		)
	;
	
interfaceMethodDeclaration [SigEnv e]
	:	#(	METHOD_DECL attributes[e] modifiers[e] type[e] qualifiedIdentifier[e]
		    EMPTY_STMT 
			( f:formalParameterList[e] )?
		)  
	;
	
interfacePropertyDeclaration [SigEnv e]
	:	#(	PROPERTY_DECL attributes[e] modifiers[e] type[e] identifier[e]
			accessorDeclarations[e]/*cc:*/CLOSE_CURLY 
		)
	;
	
interfaceEventDeclaration [SigEnv e]
	:	#(/*evt:*/EVENT attributes[e] modifiers[e] 
			type[e] variableDeclarator[e]		 
		)
	;
	
interfaceIndexerDeclaration [SigEnv e]
	:	#(	INDEXER_DECL attributes[e] modifiers[e] type[e]/*t:*/THIS 
			formalParameterList[e] 
			accessorDeclarations[e]/*cc:*/CLOSE_CURLY 
		)
	;

	
//
//	A.2.10 Enums
//

enumDeclaration [SigEnv e]
  { string t = null; 
    EnumRepTemplate cla = null;
    SigEnv env = new SigEnv(); 
  }	:	#( ENUM attributes[e] mod:modifiers[e] id:identifier[e]
			t=enumImplements[e]
			#(  TYPE_BODY 
					mem:enumMemberDeclarations[env, nameSpace + #id.getText()]			  
			    CLOSE_CURLY 
			)
			{
			   cla = new EnumRepTemplate(nameSpace + #id.getText(), CollectUsePath(), new string[] {"System.Enum"}, 
										  (MethodRepTemplate[]) env.Methods.ToArray(typeof(MethodRepTemplate)),
										  (PropRepTemplate[]) env.Properties.ToArray(typeof(PropRepTemplate)),
										  (FieldRepTemplate[]) env.Fields.ToArray(typeof(FieldRepTemplate)),
										  (CastRepTemplate[]) env.Casts.ToArray(typeof(CastRepTemplate)),
										  new string[0],
										  null
										  );
			   appEnv[nameSpace + #id.getText()] = cla; 
			}
		) 
	;

enumImplements [SigEnv e] returns [string t]
  { t = null; }
	: #( ENUM_BASE ( t=type[e] )? { // By default an enum maps to an int 
									if (t == null) t = "int"; 
								  } 
	)
	;
	
enumMemberDeclarations [SigEnv e, string t]
	: #( MEMBER_LIST 
			( enumMemberDeclaration[e, t] )* 
		) 
	;
		
enumMemberDeclaration [SigEnv e, string t]
	:	#( id:IDENTIFIER   {  e.Fields.Add(new FieldRepTemplate(t, #id.getText())); } attributes[e]
				( c:constantExpression[e] )?
		)
 	;


//
// A.2.11 Delegates
//

delegateDeclaration [SigEnv e]
	:	#(/*dlg:*/DELEGATE attributes[e] modifiers[e] 
			type[e] identifier[e] ( f:formalParameterList[e] )? 
		)
	;
	

//
// A.2.12 Attributes
//

globalAttributes [SigEnv e]
	:	#(	GLOBAL_ATTRIBUTE_SECTIONS 
			(	globalAttributeSection[e]
			|	preprocessorDirective[e, CodeMaskEnums.GlobalAttributes]
			)*
		)
	;
	
globalAttributeSection [SigEnv e]
	:	#(/*sect:*/GLOBAL_ATTRIBUTE_SECTION  
			( attribute[e] )+  
		)
	;

attributes [SigEnv e]
	:	#(	ATTRIBUTE_SECTIONS 
			(	attributeSection[e]
			|	preprocessorDirective[e, CodeMaskEnums.Attributes]
			)*
		)
	;
	
attributeSection [SigEnv e]
	:	#(/*sect:*/ATTRIBUTE_SECTION  ( attributeTarget[e] )?
			( attribute[e] )+  
		)
	;
	
attributeTarget[SigEnv e]
	:	(/*fv:*/"field"			
		|/*ev:*/EVENT			
		|/*mv:*/"method"			
		|/*mo:*/"module"			
		|/*pa:*/"param"			
		|/*pr:*/"property"		
		|/*re:*/RETURN			
		|/*ty:*/"type"			
		)
	;

attribute [SigEnv e]
	:	#( ATTRIBUTE typeName[e] attributeArguments[e] )
	;
	
attributeArguments [SigEnv e]
	:	( positionalArgumentList[e] )? ( namedArgumentList[e] )? 
	;
	
positionalArgumentList [SigEnv e]
	:	#(	POSITIONAL_ARGLIST positionalArgument[e]
			( positionalArgument[e] )* 
		)
	;
	
positionalArgument [SigEnv e]
	:	#( POSITIONAL_ARG attributeArgumentExpression[e] )
	;
	
namedArgumentList [SigEnv e]
	:	#(	NAMED_ARGLIST namedArgument[e]
			( namedArgument[e] )* 
		)
	;
	
namedArgument [SigEnv e]
	:	#( NAMED_ARG identifier[e] attributeArgumentExpression[e] )
	;
	
attributeArgumentExpression [SigEnv e]
	:	#( ATTRIB_ARGUMENT_EXPR expression[e] )
	;

//
// A.3 Grammar extensions for unsafe code
// 

fixedPointerDeclarator [SigEnv e]
	:	#( PTR_DECLARATOR identifier[e] fixedPointerInitializer[e] )
	;
	
fixedPointerInitializer [SigEnv e]
	:	#(	PTR_INIT
			(/*b:*/BIN_AND variableReference[e]
			|	expression[e]
			)
		)
	;	
	
stackallocInitializer [SigEnv e]
	:	#(/*s:*/STACKALLOC unmanagedType[e]  expression[e]  )
	;

//======================================
// Preprocessor Directives
//======================================

justPreprocessorDirectives [SigEnv e]
	:	#(	PP_DIRECTIVES 
			(	preprocessorDirective[e, CodeMaskEnums.PreprocessorDirectivesOnly] 
			)* 
		)
	;
	
preprocessorDirective [SigEnv e, CodeMaskEnums codeMask]
	:	#(PP_DEFINE   PP_IDENT  )
	|	#(/*u1:*/PP_UNDEFINE /*u2:*/PP_IDENT  )
	|	#(/*l1:*/PP_LINE    
			(/*l2:*/DEFAULT   
			|/*l3:*/PP_NUMBER  (/*l4:*/PP_FILENAME  )? 
			)
		)
	|	#(/*e1:*/PP_ERROR    ppMessage[e] )
	|	#(/*w1:*/PP_WARNING  ppMessage[e] )
	|	regionDirective[e, codeMask]
	|	conditionalDirective[e, codeMask]
	;
	
regionDirective [SigEnv e, CodeMaskEnums codeMask]
	:	#(PP_REGION  ppMessage[e] b:directiveBlock[e, codeMask]
			#(PP_ENDREGION  ppMessage[e] )
		)
	;

conditionalDirective [SigEnv e, CodeMaskEnums codeMask]   // Assume condition is true for now ...
	:	#(PP_COND_IF         preprocessExpression[e]  th:directiveBlock[e, codeMask]
			( #(PP_COND_ELIF  preprocessExpression[e]  directiveBlock[e, codeMask] ) )*
			( #(PP_COND_ELSE                           directiveBlock[e, codeMask] ) )?
		  PP_COND_ENDIF     
		) 
	;

directiveBlock [SigEnv e, CodeMaskEnums codeMask]
	:	#(	PP_BLOCK
			(	{ NotExcluded(codeMask, CodeMaskEnums.UsingDirectives) }?				usingDirective[e]
			|	{ NotExcluded(codeMask, CodeMaskEnums.GlobalAttributes) }?				globalAttributeSection[e]
			|	{ NotExcluded(codeMask, CodeMaskEnums.Attributes) }?					attributeSection[e]
			|	{ NotExcluded(codeMask, CodeMaskEnums.NamespaceMemberDeclarations) }?	namespaceMemberDeclaration[e]
			|	{ NotExcluded(codeMask, CodeMaskEnums.ClassMemberDeclarations) }?		classMemberDeclaration[e]
			|	{ NotExcluded(codeMask, CodeMaskEnums.StructMemberDeclarations) }?		structMemberDeclaration[e]
			|	{ NotExcluded(codeMask, CodeMaskEnums.InterfaceMemberDeclarations) }?	interfaceMemberDeclaration[e]
			|	{ NotExcluded(codeMask, CodeMaskEnums.Statements) }?					statement[e]
			|	preprocessorDirective[e, codeMask]
			)*
		)
	;
	
ppMessage [SigEnv e]
	:	#(	PP_MESSAGE
			(/*m1:*/PP_IDENT 		
			|/*m2:*/PP_STRING 		
			| /*m3:*/PP_FILENAME 		
			| /*m4:*/PP_NUMBER 		
			)*
		)
	;

preprocessExpression [SigEnv e]
	:	#( PP_EXPR preprocessExpr[e] )
	;

preprocessExpr [SigEnv e]
	:	#(/*o:*/LOG_OR    preprocessExpr[e]  preprocessExpr[e] )
	|	#(/*a:*/LOG_AND   preprocessExpr[e]  preprocessExpr[e] )
	|	#(/*e:*/EQUAL     preprocessExpr[e]  preprocessExpr[e] )
	|	#(/*n:*/NOT_EQUAL preprocessExpr[e]  preprocessExpr[e] )
	|	preprocessPrimaryExpression[e]
	;
	
preprocessPrimaryExpression [SigEnv e]
	:/*i:*/PP_IDENT		
	|/*tr:*/TRUE			
	|/*fa:*/FALSE		
	|	#(/*l:*/LOG_NOT 	 preprocessPrimaryExpression[e] )
	|	#(/*p:*/PAREN_EXPR  preprocessExpr[e]  )
	;
