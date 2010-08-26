header
{
	using System.IO;
	using System.Text;
	using System.Collections;
	using System.Globalization;
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
** --  It is important that we don't share parts of the AST (e.g., when we copy the namespace
**     into each compilation unit). BE CAREFUL TO CREATE A FRESH COPY INSTEAD OF SHARING.
**   
** --  We throw out nearly anything embedded in Pre Processing Directives, can we, should we do better?
**
*/
class CSharpTranslator extends TreeParser("RusticiSoftware.Translator.JavaTreeParser");

options
{
	importVocab						= CSharpJava;
	buildAST						= true;
	ASTLabelType					= "ASTNode";
	defaultErrorHandler				= true;
}

//=============================================================================
// Start of CODE
//=============================================================================

{	
	// counter so that dummy Catchall Vars will be unique 
	private int dummyCatchallCtr = 0;
	
	// throw 'holes' for the exception being caught in the current context
	private ArrayList currExHoles = new ArrayList();
	 
	private Hashtable defines = new Hashtable(); 
	
	private bool NotExcluded(CodeMaskEnums codeMask, CodeMaskEnums construct)
	{
		return ((codeMask & construct) != 0 );
	}
	
	    
        // If this is the Main method then return a wrapper 'main' method, else return null
        private AST WrapMainMethod(AST mods, AST typ, AST id, AST ps)
        {
            if (id.getText() != "Main")
                // Quick exit
                return null;
            else
            {   
                // Check return type is int or void
                // typ == #( TYPE (identifier | predefinedType | VOID) #(ARRAY_RANKS (rankSpecifier)*) )
                AST rettyp = typ.getFirstChild();
                if (typ.getFirstChild().getNextSibling().getFirstChild() == null &&
                    (rettyp.Type == VOID || rettyp.Type == INT))
                   {
                      // return type ok, check params is empty or string[], looking for
                      // #(	FORMAL_PARAMETER_LIST #( PARAMETER_FIXED type[w] identifier[w]) ) 
                      if (ps.getNumberOfChildren() < 2)
                      {
                         AST arg = ps.getFirstChild();
                         if (arg == null ||
                              // Arguments type is string
                             (arg.getFirstChild().getFirstChild().Type == STRING &&
                              // and it is a single array
                              arg.getFirstChild().getFirstChild().getNextSibling().getFirstChild().Type == ARRAY_RANK &&
                              arg.getFirstChild().getFirstChild().getNextSibling().getFirstChild().getFirstChild() == null)) 
                         {
                            // Finally,  is it public and static?
                            // keving:  According to $3.1 the Main method does not have to be public
                            AST m = mods.getFirstChild();
                            bool stat = false;
                            // mbool pub = false;
                            while (m != null) 
                            {
                                if (m.Type == STATIC)
                                  stat = true;
                                //if (m.Type == PUBLIC)
                                  //pub = true;
                                m = m.getNextSibling();  
                            }
                            if (stat)// && pub) 
                            {
                                // Found a Main method, construct wrapper
                                // public static void main(String[] args) 
                                ASTNode ret =  #( [METHOD_DECL],
													#( [MODIFIERS], [PUBLIC, "public"], [STATIC, "static"] ),
													#( [TYPE], [VOID, "void"], #( [ARRAY_RANKS] ) ),
													[IDENTIFIER, "main"],
													#( [FORMAL_PARAMETER_LIST], 
														#( [PARAMETER_FIXED], 
															 #( [TYPE], [STRING, "String"], #( [ARRAY_RANKS] , [ARRAY_RANK] ) ),
															[IDENTIFIER, "args"]
														) 
													), #( [THROWS, "throws"], [IDENTIFIER, "Exception"] ) );
								// The body varies depending on return type of Main and arguments
								AST mainArgs = null;
								string innerMain = this.ClassInProcess + ".Main(${args})";
								if (arg != null)
								   mainArgs = #( [EXPR], [IDENTIFIER, "args"] ); 
								AST mainCall = #( [EXPR],
													#( [JAVAWRAPPER],
													    #([IDENTIFIER, innerMain]),
														#([IDENTIFIER, "${args}"]), #([EXPR_LIST], mainArgs)
													 )
											     );
								AST wrappedMainCall = null; 
								if (rettyp.Type == INT) 
									wrappedMainCall = #( [EXPR],
															#( [JAVAWRAPPER],
															    #( [IDENTIFIER, "System.exit(${call})"] ),
																	#([IDENTIFIER, "${call}"]), #( [EXPR_LIST], mainCall )
																 ) );
								else
								    wrappedMainCall = mainCall;	 												 
								ret.addChild( #([BLOCK], #([EXPR_STMT], wrappedMainCall)) );
								return ret;
                            }
                            else
                              return null;
                         }
                         else 
                           return null;
                       }
                       else
                         return null;
                   }
                 else  
                   return null;
            } 
        }
        
        
        private ASTNode SmotherCheckedExceptions(ASTNode b, String reThrow) 
        {
        
        	
        	ASTNode retAST = #( [TRY, "try"],
								  astFactory.dupTree(b),
							      #( [CATCH, "catch"],
									   #( [FIELD_DECL, "FIELD_DECL"], 
										  #( [MODIFIERS, "MODIFIERS"] ),
										  #( [TYPE, "type"],
										    #( [JAVAWRAPPER], [IDENTIFIER, "Exception"] ),
										    #( [ARRAY_RANKS] ) 
										   ),
										  #( [VAR_DECLARATOR, "VAR_DECLARATOR"],
												#( [IDENTIFIER, "__e"] ) 
										   ) ),
									   #( [BLOCK], 
											#( [THROW, "throw"],
												#([EXPR], #( [OBJ_CREATE_EXPR, "new"], 
													#( [TYPE], #([JAVAWRAPPER], [IDENTIFIER, reThrow]), #([ARRAY_RANKS]) ), 
											        #( [EXPR_LIST], #([EXPR],  #([IDENTIFIER, "__e"]) ) ) ) )
												)) 
								       ) );
		    return retAST;
		    
		}
        
        // Strip one rank from array type t
        // t = #( TYPE baseType #( ARRAY_RANKS #( ARRAY_RANK COMMA* )* )
        // NOTE: Updates t in place
        private ASTNode StripOneRank(ASTNode t)
        {
			ASTNode baseType = (ASTNode) t.getFirstChild();
			ASTNode arrayRanks = (ASTNode) baseType.getNextSibling();
			ASTNode rank = (ASTNode) arrayRanks.getFirstChild();
			
			if (rank == null)
			{
			    Console.Error.WriteLine("ERROR: Expected array type");
			}
			else
			{
			    if (rank.getNextSibling() == null)
			    {
			       // Only one rank
			       arrayRanks.setFirstChild(null);
			    }
			    else
			    {
			       // Remove final rank (we could just remove the first, but ....) 
			       ASTNode prev = rank;  // Init to 1st element 
			       rank = (ASTNode) rank.getNextSibling(); // Init to 2nd element
				   while (rank.getNextSibling() != null)  // Will always succeed first time through
				   {
				      prev = rank;
				      rank = (ASTNode) rank.getNextSibling();
				   }
				   prev.setNextSibling(null);
				 }
			}
			return t;	 
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
compilationUnit! [Object w]
	:	#(	COMPILATION_UNIT
			justPreprocessorDirectives[w]
			uses:usingDirectives[w]
			globalAttributes[w]
			cus:namespaceMemberDeclarations[w, #uses, null /* initial namespace */]
		)
		{ ## = #( [MULTI_COMPILATION_UNITS], cus) ; }
	;
	
usingDirectives [Object w]
	:	#(	USING_DIRECTIVES
			(	preprocessorDirective[w, CodeMaskEnums.UsingDirectives]
			|	usingDirective[w] 
			)*
		) 
	;
	
usingDirective [Object w]
	:	#( USING_NAMESPACE_DIRECTIVE 	
			pn:qualifiedIdentifier[w] 			
		) 
	|	#(	USING_ALIAS_DIRECTIVE     	
			alias:identifier[w] 					
			pna:qualifiedIdentifier[w] 			
		)
	;

namespaceMemberDeclarations [Object w, ASTNode uses, ASTNode pns]
	:	(	namespaceMemberDeclaration[w, uses, pns]
		|	preprocessorDirective[w, CodeMaskEnums.NamespaceMemberDeclarations]
		)* 
	;
	
namespaceMemberDeclaration [Object w, ASTNode uses, ASTNode ns]
	:	namespaceDeclaration[w, uses, ns]
	|	typeDeclaration[w, uses, ns, true]
	;
	
typeDeclaration! [Object w, ASTNode uses, ASTNode ns, bool topLevel]
		{ if (topLevel) {
			// reset java imports for each compilation unit 
			initialize();
		  };
		}
		:	cla:classDeclaration[w]
				{ if (topLevel) {					
				     ## = #( [COMPILATION_UNIT], 
							   #( [PACKAGE_DEF, "package"], astFactory.dupTree(ns)), 
							       astFactory.dupTree(uses), GetImports(), 
							       #cla );
				  }			    
				  else {
				     ## = #cla ;
				  }; }
		|	str:structDeclaration[w]
				{ if (topLevel) {
					  ## = #( [COMPILATION_UNIT], 
								#( [PACKAGE_DEF, "package"], astFactory.dupTree(ns)),
								astFactory.dupTree(uses), GetImports(),
								#str ); 
				  } else {
					  ## = #str;
				  }; }
		|	iface:interfaceDeclaration[w]		
				{ if (topLevel) {
					  ## = #( [COMPILATION_UNIT], 
								#( [PACKAGE_DEF, "package"], astFactory.dupTree(ns)),
								astFactory.dupTree(uses), GetImports(),
								#iface ); 
				  } else {
					  ## = #iface;
				  }; }
		|	enm:enumDeclaration[w]
				{ if (topLevel) {
					  ## = #( [COMPILATION_UNIT], 
								#( [PACKAGE_DEF, "package"], astFactory.dupTree(ns)),
								astFactory.dupTree(uses), GetImports(),
								#enm ); 
				  } else {
					  ## = #enm;
				  }; }		
		|	delegateDeclaration[w]	
	;

namespaceDeclaration! [Object w, ASTNode uses, ASTNode ns]
 { ASTNode add_ns = null; 
   ASTNode new_ns = null, tmp = null;
   }
	:	#(  NAMESPACE  
			m_ns:qualifiedIdentifier[w] { if (ns == null) 
											// easy, replace with new namespace 
											add_ns = #m_ns;
										  else {
										    if (ns.Type == IDENTIFIER) 
												// A single identifier, just prepend it to existing namespace
										        add_ns = #( [DOT], #( [IDENTIFIER, ns.getText()] ), #m_ns);
										    else {
												// A dotted identifier list, build new qualified id 
												tmp = (ASTNode) ns.getFirstChild();
												new_ns = #( [DOT], #( [IDENTIFIER, tmp.getText()] ) );  
												add_ns = new_ns;     // remember head of new namespace  
												//new_ns = (ASTNode) add_ns.getFirstChild();
												tmp = (ASTNode) tmp.getNextSibling();   
												while (tmp.Type == DOT) {
													tmp = (ASTNode) tmp.getFirstChild();
													new_ns.addChildEx( #( [DOT], #( [IDENTIFIER, tmp.getText()] ) ) );
													new_ns = (ASTNode) new_ns.getFirstChild().getNextSibling(); // Newly added child
													tmp = (ASTNode) tmp.getNextSibling();
												}
												new_ns.addChildEx(#( [DOT], #( [IDENTIFIER, tmp.getText()] ), #m_ns));
											} 
										  } ; }
			bdy:namespaceBody[w, uses, add_ns] 
		) { ## = #bdy; }
	;
	
namespaceBody! [Object w, ASTNode uses, ASTNode ns]
 { ASTNode uses_plus = null; }
	:	#( NAMESPACE_BODY  m_uses:usingDirectives[w]  
				{ uses_plus = (ASTNode) astFactory.dupTree(uses); 
				  uses_plus.addChild(#m_uses.getFirstChild()); 
				} 
			mem:namespaceMemberDeclarations[w, uses_plus, ns] 
			CLOSE_CURLY    
		) { ## = #mem; }
	;
	
classModifiers [Object w]
	:	modifiers[w]			// indirection for any special processing
	;
		
modifiers [Object w] // TODO: If there are no access modifiers then make it private (check)
	:	#( MODIFIERS ( modifier[w] )* )
	;

modifier [Object w]
	:	( ABSTRACT				// tick
		|/*nw:*/NEW			
		|/*ov:*/OVERRIDE		
		| PUBLIC				// tick	
		| PROTECTED				// tick	
		|! INTERNAL		{## = null;}    // equate internal to package level. This is default in Java. 		
		| PRIVATE				// tick	
		|! SEALED       { ## = #( [FINAL, "final"] ); }              // tick
		|/*st:*/STATIC		
		|/*vi:*/VIRTUAL		
		|/*ext:*/EXTERN		
		|! READONLY		{ ## = #( [FINAL, "final"] ); }              // tick
		|/*un:*/UNSAFE		
		|/*vo:*/VOLATILE		
		)
	;


typeName [Object w]
	:	predefinedType[w]
	|	qualifiedIdentifier[w]
	;
	
classTypeName [Object w]
	:	qualifiedIdentifier[w]
	|!   OBJECT    { ## = #( [DOT, "DOT"], #( [IDENTIFIER, "System"] ),	#( [IDENTIFIER, "Object"] ) ); }		
	|/*str:*/STRING			
	;
	
identifier [Object w]
	: id:IDENTIFIER	{ fixBrokenIds(##); }	
	;
	
qualifiedIdentifier [Object w]
	:	(	identifier[w]
		|	#(DOT identifier[w]	qualifiedIdentifier[w] )
		) 
	;

	
//
// A.2.2 Types
//

type [Object w]
	:	#(	TYPE 
			( 	qualifiedIdentifier[w]
			| 	predefinedType[w]
			|   VOID 
			)
			pointerSpecifier[w]! // TODO: Bleargh. We don't support pointer types
			rankSpecifiers[w]			
		)
	;
	
pointerSpecifier [Object w]
	:	#(	STARS 
			( STAR 
			)* 
		)
	;
	
classType [Object w]
	:	qualifiedIdentifier[w]
	|!  OBJECT  { ## = #( [DOT, "DOT"], #( [IDENTIFIER, "System"] ),	#( [IDENTIFIER, "Object"] ) ); }			
	|/*str:*/STRING			
	;
	
interfaceType [Object w]
	:	qualifiedIdentifier[w]
	;

delegateType [Object w]
	:	qualifiedIdentifier[w]		// typeName
	;

/*	
pointerType
	:	unmanagedType STAR
	|	VOID STAR
	;
*/	
unmanagedType [Object w]
	:	qualifiedIdentifier[w]		// typeName
	;
	
//
// A.2.3 Variables
//

variableReference [Object w]
	:	expression[w]
	;

//
// A.2.4 Expressions
//
	
argumentList [Object w]  // Simplify by making it an EXPR_LIST
	:	#(	ARG_LIST { ##.setType(EXPR_LIST); ##.setText("EXPR_LIST"); } argument[w] ( argument[w] )*
		)
	;
	
argument [Object w]
	:	expression[w]
	|!	#(/*r:*/REF variableReference[w] )
	|!	#(/*o:*/OUT variableReference[w] )
	;

constantExpression [Object w]
	:	expression[w]
	;
	
booleanExpression [Object w]
	:	expression[w]
	;
	
expressionList [Object w]
	:	#(	EXPR_LIST expression[w] ( expression[w] )*
		)
	;

expression [Object w]
	:	#( EXPR expr[w] )
	;
	
expr [Object w]
		// assignmentExpression
		//
	:	#( ASSIGN         expr[w]  expr[w] )
	// We expand 
	|!	#( PLUS_ASSIGN    pal:expr[w]  par:expr[w]   { ## = #( [ASSIGN, "="], astFactory.dupTree(#pal), #( [PLUS, "+"], astFactory.dupTree(#pal), astFactory.dupTree(#par) ) ); }    )
	|!	#( MINUS_ASSIGN   mal:expr[w]  mar:expr[w]   { ## = #( [ASSIGN, "="], astFactory.dupTree(#mal), #( [MINUS, "-"], astFactory.dupTree(#mal), astFactory.dupTree(#mar) ) ); }   )
	|!	#( STAR_ASSIGN    sal:expr[w]  sar:expr[w]   { ## = #( [ASSIGN, "="], astFactory.dupTree(#sal), #( [STAR, "*"], astFactory.dupTree(#sal), astFactory.dupTree(#sar) ) ); }    )
	|!	#( DIV_ASSIGN     dal:expr[w]  dar:expr[w]   { ## = #( [ASSIGN, "="], astFactory.dupTree(#dal), #( [DIV, "/"], astFactory.dupTree(#dal), astFactory.dupTree(#dar) ) ); }     )
	|!	#( MOD_ASSIGN     moal:expr[w]  moar:expr[w] { ## = #( [ASSIGN, "="], astFactory.dupTree(#moal), #( [MOD, "%"], astFactory.dupTree(#moal), astFactory.dupTree(#moar) ) ); }  )
	|!	#( BIN_AND_ASSIGN baal:expr[w]  baar:expr[w] { ## = #( [ASSIGN, "="], astFactory.dupTree(#baal), #( [BIN_AND, "&"], astFactory.dupTree(#baal), astFactory.dupTree(#baar) ) ); }   )
	|!	#( BIN_OR_ASSIGN  boal:expr[w]  boar:expr[w] { ## = #( [ASSIGN, "="], astFactory.dupTree(#boal), #( [BIN_OR, "|"], astFactory.dupTree(#boal), astFactory.dupTree(#boar) ) ); }    )
	|!	#( BIN_XOR_ASSIGN bxal:expr[w]  bxar:expr[w] { ## = #( [ASSIGN, "="], astFactory.dupTree(#bxal), #( [BIN_XOR, "^"], astFactory.dupTree(#bxal), astFactory.dupTree(#bxar) ) ); }   )
	|!	#( SHIFTL_ASSIGN  slal:expr[w]  slar:expr[w] { ## = #( [ASSIGN, "="], astFactory.dupTree(#slal), #( [SHIFTL, "<<"], astFactory.dupTree(#slal), astFactory.dupTree(#slar) ) ); }    )
	|!	#( SHIFTR_ASSIGN  sral:expr[w]  srar:expr[w] { ## = #( [ASSIGN, "="], astFactory.dupTree(#sral), #( [SHIFTR, ">>"], astFactory.dupTree(#sral), astFactory.dupTree(#srar) ) ); }    )
		// conditionalExpression
		//
	|	#( QUESTION       expr[w]  expr[w]  expr[w] )
	
		// conditional-XXX-Expressions
		//
	|	#( LOG_OR         expr[w]  expr[w] )
	|	#( LOG_AND        expr[w]  expr[w] )
		
		// bitwise-XXX-Expressions
		//
	|	#( BIN_OR         expr[w]  expr[w] )
	|	#( BIN_XOR        expr[w]  expr[w] )
	|	#( BIN_AND        expr[w]  expr[w] )

		// equalityExpression
		//
	|	#( EQUAL          expr[w]  expr[w] )
	|	#( NOT_EQUAL      expr[w]  expr[w] )

		// relationalExpression
		//
	|	#( LTHAN          expr[w]  expr[w] )
	|	#( GTHAN          expr[w]  expr[w] )
	|	#( LTE            expr[w]  expr[w] )
	|	#( GTE            expr[w]  expr[w] )
	|	#( IS             expr[w]  type[w] ) {##.setType(INSTANCEOF); ##.setText("instanceof"); }
	|!	#( AS             e:expr[w]  t:type[w] ) { ASTNode e1 = (ASTNode) astFactory.dupTree(#e);
												   ASTNode e2 = (ASTNode) astFactory.dupTree(#e);
												   ASTNode t1 = (ASTNode) astFactory.dupTree(#t);
												   ASTNode t2 = (ASTNode) astFactory.dupTree(#t);
												   ASTNode t3 = (ASTNode) astFactory.dupTree(#t);
												   ## = #( [QUESTION, "?"], #( [INSTANCEOF, "instanceof"], e1, t1),
																			#( [CAST_EXPR], t2, e2),
																			#( [CAST_EXPR], t3, #( [NULL, "null"]))); }
		// shiftExpression
		//
	|	#( SHIFTL         expr[w]  expr[w] )
	|	#( SHIFTR         expr[w]  expr[w] )

		// additiveExpression
		//
	|	#( PLUS           expr[w]  expr[w] )
	|	#( MINUS          expr[w]  expr[w] )
		// multiplicativeExpression
		//
	|	#( STAR           expr[w]  expr[w] )
	|	#( DIV            expr[w]  expr[w] )
	|	#( MOD            expr[w]  expr[w] )
	|	unaryExpression[w]
	;	

unaryExpression [Object w]
	:	#( CAST_EXPR 			 type[w] expr[w] )
	|	#( INC              	 expr[w] )
	|	#( DEC              	 expr[w] )
	|	#( UNARY_PLUS       	 expr[w] )
	|	#( UNARY_MINUS      	 expr[w] )
	|	#( LOG_NOT             expr[w] )
	|	#( BIN_NOT			 expr[w] )
	|	#(/*p:*/PTR_INDIRECTION_EXPR  expr[w] )
	|	#(/*a:*/ADDRESS_OF_EXPR       expr[w] )
	|	primaryExpression[w]
	;
	
primaryExpression [Object w]
	:	#(	// invocationExpression ::= primaryExpression OPEN_PAREN ( argumentList )? CLOSE_PAREN 
			INVOCATION_EXPR			primaryExpression[w] 
									(a:argumentList[w])?   { if (a == null) ##.addChild( #( [EXPR_LIST, "EXPR_LIST"] ) ); }
		)
	|	#(	// elementAccess		::= primaryNoArrayCreationExpression OPEN_BRACK expressionList CLOSE_BRACK
		/*e:*/ELEMENT_ACCESS_EXPR		primaryExpression[w] 
										expressionList[w]    
		)
	|	#(	// pointerElementAccess ::= primaryNoArrayCreationExpression OPEN_BRACK expression     CLOSE_BRACK
		/*p:*/PTR_ELEMENT_ACCESS_EXPR	primaryExpression[w]  
										expressionList[w]    
		)
	|	#(	// memberAccess		    ::= primaryExpression DOT identifier
		    MEMBER_ACCESS_EXPR      									
			(	type[w]
			|	primaryExpression[w]
			)
			identifier[w]
		)
	|	// pointerMemberAccess
		#(/*d:*/DEREF                   primaryExpression[w]  identifier[w] )
	|	// postIncrementExpression
		#( POST_INC_EXPR          primaryExpression[w]  )
	|	// postDecrementExpression
		#( POST_DEC_EXPR          primaryExpression[w]  )
	|	basicPrimaryExpression[w]
	;

basicPrimaryExpression [Object w]
	:	literal[w]
	|	identifier[w]										// simpleName
	|!	// parenthesizedExpression
		//
		#( PAREN_EXPR  e:expr[w]  )    { ## = #e; }
	| THIS 		
	|!	#( BASE		
			(	i:identifier[w]   { ## = #( [MEMBER_ACCESS_EXPR, "MEMBER_ACCESS_EXPR"],
												[SUPER, "super"], #i); }
			|	expressionList[w]  // TODO:access to base class indexer ... 
			)
		) 
	|	newExpression[w]
	|!	// typeofExpression    rewrite to call <typename>.class
		//
		#( TYPEOF 	 t:type[w] )   
		     { 
		         string classCall = typeToString(#t, false) + ".class"; ## =  #( [JAVAWRAPPER], [IDENTIFIER, classCall] ); 
		         ##.DotNetType = new TypeRep();
		         ##.DotNetType.TypeName = "System.Type"; /* ugly, will fill this type in on the next pass when we have correct type context */ 
		     }
//	|!	// typeofExpression    rewrite to call Class.forName("type name");
//		//
//		#( TYPEOF 	 t:type[w] )   {## =  #( [INVOCATION_EXPR, "INVOCATION_EXPR"],
//												#( [JAVAWRAPPER],
//													#( [IDENTIFIER, "Class.forName"] )
//												  ),
//												#( [EXPR_LIST, "EXPR_LIST"],
//													#( [EXPR, "EXPR"],
//														[STRING_LITERAL, typeToString(#t)] ) )
//											);
//									addImport("RusticiSoftware.JavaSupport.ClassSupport");   // To get a forName that converts checked exception to unchecked
//									}
	|	#(/*s:*/SIZEOF    	 unmanagedType[w]  )
	|!	#(/*c:*/CHECKED   	 ce:expression[w]  )     { ## = (ASTNode) #ce.getFirstChild(); }          // keving: TODO RusticiSoftware.ScormContentPlayer.Logic\Types\ScormTimeSpan.cs uses checked expressions
	|!	#(/*u:*/UNCHECKED 	 ue:expression[w]  )     { ## = (ASTNode) #ue.getFirstChild(); }     
	;

newExpression [Object w]
		// objectCreationExpression	  
		//
	:	#(OBJ_CREATE_EXPR  type[w]  (al:argumentList[w])?  )  { if (#al == null) ##.addChild( #([EXPR_LIST, "EXPR_LIST"]) ); }
		// delegateCreationExpression	  
		//
	|	#(/*dl:*/DLG_CREATE_EXPR  type[w]  argumentList[w]  )
		// arrayCreationExpression
		//
	|	#( ARRAY_CREATE_EXPR 
			type[w]										// nonArrayType ( rankSpecifiers )?
			(	 arrayInitializer[w]
			|	 expressionList[w]  
				 rankSpecifiers[w] ( arrayInitializer[w] )? 
			)
		)
	;

literal [Object w]
	: TRUE				
	| FALSE			
	|! i:INT_LITERAL		{ long val = 0;
	                          if (#i.getText().TrimStart().StartsWith("0x"))
	                             val = Int64.Parse(#i.getText().TrimStart().Substring(2), NumberStyles.AllowHexSpecifier); 
	                           else
	                             val = Int64.Parse(#i.getText());
						      if (val > Int32.MaxValue) 
						        ## = #( [LONG_LITERAL, #i.getText()] );
						      else
						        ## = (ASTNode) astFactory.dupTree(#i); 
						    }		
	|! u:UINT_LITERAL	    { ulong val = 0;
	                          if (#i.getText().TrimStart().StartsWith("0x"))
	                             val = UInt64.Parse(#i.getText().TrimStart().Substring(2), NumberStyles.AllowHexSpecifier); 
	                           else
	                             val = UInt64.Parse(#i.getText());
						      if (val > UInt32.MaxValue) 
						        ## = #( [ULONG_LITERAL, #u.getText()] );
						      else
						        ## = (ASTNode) astFactory.dupTree(#u); 
						    }
	| LONG_LITERAL		
	| ULONG_LITERAL	
	| DECIMAL_LITERAL	
	| FLOAT_LITERAL	
	| DOUBLE_LITERAL	
	| CHAR_LITERAL		
	| s:STRING_LITERAL	{ String slit = #s.getText();
						  if (slit.StartsWith("@\"")) {
						     // escape string for Java
						     ##.setText("\"" + escapeJavaString(slit.Substring(2,slit.Length - 2)) + "\"");
						  }
						  // TODO: Check that C# escaped strings are Java escaped
						  ; }
	| NULL				
	;

predefinedType [Object w]
	: BOOL        {##.setText("boolean");}				 
	| BYTE		  {##.setText("byte");} // TODO: Not available		
	| CHAR				
	| DECIMAL	  {##.setText("Decimal");} // TODO: Not available		
	| DOUBLE			
	| FLOAT			
	| INT				
	| LONG				
	| OBJECT	  { ##.setText("Object"); }
	| SBYTE		  { ##.setText("byte"); }
	| SHORT			
	| STRING	 {##.setText("String");}			
	| UINT		{##.setText("int");} // TODO: Not available		
	| ULONG		{##.setText("long");} // TODO: Not available	
	| USHORT	{##.setText("short");} // TODO: Not available		
	;
	

//
// A.2.5 Statements
//

statement [Object w]
	:	#(/*l:*/LABEL_STMT identifier[w]  statement[w]
		)
	|	localVariableDeclaration[w] 
	|	localConstantDeclaration[w]
	|	embeddedStatement[w]
	|	preprocessorDirective[w, CodeMaskEnums.Statements]
	;
	
embeddedStatement [Object w]
	:	block[w]
	|   EMPTY_STMT	
	|	#( EXPR_STMT statementExpression[w]  )
	|	#(IF 
			 expression[w]  embeddedStatement[w]
			(	#(ELSE 
					embeddedStatement[w]
				)
			)? 
		)
	|!	// TODO: If the scrutinee has string type then we must convert to if-then-else :-( 
		{ ASTNode ret = #( [SWITCH, "switch"] ); }
	    #(   SWITCH 
			 se:expression[w] { ret.addChild(#se); } 
			#( OPEN_CURLY 
				( ss:switchSection[w] { ret.addChild(#ss); } )* 
			 CLOSE_CURLY 
			) 
		) { ## = ret; }
	|	#( FOR 
			#( FOR_INIT ( ( localVariableDeclaration[w] | ( statementExpression[w] )+ ) )? )
			
			#( FOR_COND ( booleanExpression[w] )? )
			
			#( FOR_ITER ( ( statementExpression[w] )+  )? )
			
			embeddedStatement[w]
		)
	|	#( WHILE booleanExpression[w] embeddedStatement[w] )
	|	#(/*doStmt:*/DO 
			embeddedStatement[w]  booleanExpression[w] 
		)
	|	#( FOREACH localVariableDeclaration[w]  expression[w] embeddedStatement[w] )
	|   BREAK		
	|   CONTINUE	
	|	#(/*gto:*/GOTO 	
			(	identifier[w] 
			|/*cse:*/CASE 	 constantExpression[w]
			|/*dfl:*/DEFAULT	
			)
			
		)
	|	#(/*rtn:*/RETURN  ( expression[w] )?  )
	|	{ bool throwExp = false; } #(  THROW   ( expression[w] { throwExp = true; } )?  ) 
	          { if (!throwExp) 
	            {
	               ASTNode hole = #( [IDENTIFIER, "ThrowHole"] );  
	               ##.addChild( #( [EXPR], hole ) );
	               // To be fixed up later in catchClause when we know what the exception var is 
	               currExHoles.Add(hole);
	            };
	          }
	|	tryStatement[w]
	|	#(/*checkedStmt:*/CHECKED 	   block[w]
		)
	|	#(/**/UNCHECKED	   block[w]
		)
	|	#(/*lockStmt:*/LOCK 
			 expression[w]  embeddedStatement[w]
		)
	|!	
		// rewrite 'using (<var decs> | <expr>) slist' to 
		// <var decs>; try <slist> finally { if (<var> != null) <var>.Dispose(); ... <expr>.Dispose(); }
	    { ASTNode decsAST = null; }  
	    #(USING 
			 rs:resourceAcquisition[w] 
			 {  // Collect all the resources from #rs that need to be Disposed of.
				ArrayList resources = new ArrayList();
				if (#rs.Type == EXPR)
				{
				   // A single resource indicated by an expression (EXPR e)
				   resources.Add(astFactory.dupTree(#rs.getFirstChild()));
				} 
				else if (#rs.Type == FIELD_DECL)
				{
				   // Collect all the variable names so that they can be disposed of later
				   ASTNode varsAST = (ASTNode) #rs.getFirstChild().getNextSibling().getNextSibling();
				   while (varsAST != null)
				   {
				      // (VAR_DECLARATOR identifier (init?))
				      resources.Add(astFactory.dupTree(varsAST.getFirstChild()));
				      varsAST = (ASTNode) varsAST.getNextSibling();
				   }   
				   // Emit variable declarations
				   decsAST = (ASTNode) astFactory.dupTree(#rs);
				}
				else
				{
				   Console.Error.WriteLine("ERROR -- (using): unexpected resource specification: ");
				}
			 }
			  slist:embeddedStatement[w]
		)	
		{
		   // Build up the try .. finally statement
		   ASTNode tryAST = null;
		   ASTNode fBlockAST = #( [BLOCK] );
		   if (slist.Type == BLOCK)
		      tryAST = #( [TRY, "try"], astFactory.dupTree(#slist));
		   else
		      tryAST = #( [TRY, "try"], #( [BLOCK], astFactory.dupTree(#slist) ) );
		   foreach (ASTNode expr in resources)
		   {
		      fBlockAST.addChild( #( [IF, "if"], 
		                                #( [EXPR], #( [NOT_EQUAL, "!="], astFactory.dupTree(expr), #( [NULL, "null"] ) ) ), 
		                                #( [BLOCK], #( [EXPR_STMT], #( [EXPR], #( [INVOCATION_EXPR], #( [MEMBER_ACCESS_EXPR], expr, [IDENTIFIER, "Dispose"] ), #( [EXPR_LIST] ) ) ) ) ) 
		                           ) );
		   }
		   tryAST.addChild( #( [FINALLY, "finally"], fBlockAST ) );  
		   ## = (decsAST == null ? tryAST : #( null, decsAST, tryAST) );
		}
	|	#(/*unsafeStmt:*/UNSAFE 
			block[w]
		)
	|	// fixedStatement
		#(/*fixedStmt:*/FIXED 
			 type[w] 
			fixedPointerDeclarator[w] (  fixedPointerDeclarator[w] )*
			
			embeddedStatement[w]
		)
	;
	
body [Object w]
	:	block[w]
	|   EMPTY_STMT
	;

block [Object w]
	:	#(BLOCK 
			( statement[w] )*
		 CLOSE_CURLY! 
		)
	;
	
statementList[Object w]
	:	#( STMT_LIST ( statement[w] )+ )
	;
	
localVariableDeclaration! [Object w]
	:	#(	LOCVAR_DECLS t:type[w] 
					{ ## = #( [FIELD_DECL, "FIELD_DECL"], 
								#( [MODIFIERS, "MODIFIERS"] ),
								#t); }
			(d:localVariableDeclarator[w] { ##.addChild(#d); } )+ 
			) 
	;
	
localVariableDeclarator [Object w]
	:	#(	VAR_DECLARATOR identifier[w] (localVariableInit[w])?	
		)
	;

localVariableInit [Object w]
	:
		#(	LOCVAR_INIT
			(	expression[w]
			|	arrayInitializer[w]
			)
		) { ##.setType(VAR_INIT); ##.setText("VAR_INIT"); }
	;
	
		
localConstantDeclaration! [Object w] // rewrite to field_decl with final modifier
	:	#(LOCAL_CONST  t:type[w] 
			{ ## = #( [FIELD_DECL, "FIELD_DECL"],
						  #( [MODIFIERS, "MODIFIERS"],
								#( [STATIC, "static"] ),
						        #( [FINAL, "final"] )
						    ), #t ); } 
			(	
				d:constantDeclarator[w] { ##.addChild(#d); }
			)+
		)
	;
	
constantDeclarator! [Object w]
	:	#(CONST_DECLARATOR i:identifier[w] c:constantExpression[w]
		) {## = #( [VAR_DECLARATOR, "VAR_DECLARATOR"], #i, #( [VAR_INIT, "VAR_INIT"], #c) ); }
	;
	
statementExpression! [Object w]
	:	e:expr[w] { ## = #([EXPR], #e); } 
	;
	
switchSection[Object w]
	:	#( SWITCH_SECTION switchLabels[w] statementList[w] )
	;
	
switchLabels [Object w]
	:	#(	SWITCH_LABELS 
			(	(	#(CASE  expression[w] )
				|  DEFAULT	
				)
				
			)+ 
		) { ## = (ASTNode) ##.getFirstChild(); }
	;
	
tryStatement [Object w]
	:	#( TRY 
			block[w]
			(	finallyClause[w]
			|	catchClauses[w] ( finallyClause[w] )?
			)
		)
	;
	
catchClauses [Object w]
	:	(	
			catchClause[w]
		)+
	;
	
catchClause [Object w]
 { bool guards = false; 
   ASTNode ret = #( [CATCH, "catch"] );
   ArrayList saveExHoles = currExHoles;
   currExHoles = new ArrayList();
   string exVarStr = "";
 }
	:! #( CATCH b:block[w] 
			(	t:type[w]						{ 
													exVarStr = "__dummyCatchallEx" + dummyCatchallCtr;
													dummyCatchallCtr++;
													ret.addChild( #( [FIELD_DECL, "FIELD_DECL"], 
																	#( [MODIFIERS, "MODIFIERS"] ),
																		#( [TYPE, "type"],
																		    astFactory.dupTree(#t.getFirstChild()),
																		    ( [ARRAY_RANKS] ) ),
																	    #( [VAR_DECLARATOR, "VAR_DECLARATOR"],
																			#( [IDENTIFIER, exVarStr] ) 
																				) ) ); 
												  guards = true; }
			|	l:localVariableDeclaration[w]	{ ret.addChild(#l); 
												  exVarStr = #l.getFirstChild().getNextSibling().getNextSibling().getFirstChild().getText(); 
												  guards = true; }
			)*
		) { if (!guards) {
				exVarStr = "__dummyCatchallEx" + dummyCatchallCtr;
				dummyCatchallCtr++;
				ret.addChild(#( [FIELD_DECL, "FIELD_DECL"], 
								#( [MODIFIERS, "MODIFIERS"] ),
								#( [TYPE, "type"],
									#( [JAVAWRAPPER], [IDENTIFIER, "Exception"] ),
									#( [ARRAY_RANKS] ) ),
								#( [VAR_DECLARATOR, "VAR_DECLARATOR"],
									#( [IDENTIFIER, exVarStr] ) 
									) ));
			} 
			// Fill in any holes
			foreach (ASTNode idAST in currExHoles)
			{
			    idAST.setText(exVarStr);
			}
			currExHoles = saveExHoles;
		    ret.addChild(#b);
		    ## = ret; }
	;
	
finallyClause [Object w]
	:	#( FINALLY 
			block[w]
		)
	;
	
resourceAcquisition[Object w]
	:	localVariableDeclaration[w]
	|	expression[w]
	;
	
//	
// A.2.6 Classes
//

classDeclaration [Object w]
  {string saveClass = this.ClassInProcess; }
	:!	#( CLASS
			attributes[w]     // todo: attributes 
			mod:classModifiers[w]  
			id:identifier[w]    { this.ClassInProcess = #id.getText(); }
			ext:classBase[w] 
			#(TYPE_BODY  mem:classMemberDeclarations[w] CLOSE_CURLY ) 
		) 
		 {
		    ASTNode firstParent = (ASTNode) #ext.getFirstChild(); 
		    if ( firstParent != null && firstParent.getNextSibling() == null && idToString(firstParent) == "System.Attribute" ) {
		      // A class that only inherits System.Attribute. Must be a an attribute definition.
		      // TODO: We don't handle annotations with parameters yet.
		      ## = #( [ANNOTATION], #mod, #id, #( [MEMBER_LIST]) );
		    }
		    else {
		      ## = #( [CLASS], #mod, #id, #ext, #mem );
		    } 
		  this.ClassInProcess = saveClass;
		 }
	;
	
classBase [Object w]
	:! { ## = #( [CLASS_BASE] ); }
	   #( CLASS_BASE
			(	
				t:type[w]! { ##.addChild( astFactory.dupTree(#t.getFirstChild()) ); } // Extract identifier from type info
			)* 
		)
	;
	
classMemberDeclarations [Object w]
	:	#(	MEMBER_LIST
			(	classMemberDeclaration [w]
			|	preprocessorDirective[w, CodeMaskEnums.ClassMemberDeclarations]
			)*
		)
	;
	
classMemberDeclaration [Object w]
	:	(	destructorDeclaration[w]
		|	typeMemberDeclaration[w]
		)
	;
	
typeMemberDeclaration [Object w]
	:	(	constantDeclaration[w]
		|	eventDeclaration[w]
		|	constructorDeclaration[w]
		|	staticConstructorDeclaration[w]
		|	propertyDeclaration[w]
		|	methodDeclaration[w]
		|	indexerDeclaration[w]
		|	fieldDeclaration[w]
		|	operatorDeclaration[w]
		|	typeDeclaration[w, null, null, false]
		)
	;
	
constantDeclaration! [Object w]
	:	#(CONST attributes[w]! m:modifiers[w] t:type[w] 
	          { #m.addChild( #( null, [STATIC, "static"], [FINAL, "final"] )); 
	            ## = #( [FIELD_DECL, "FIELD_DECL"], #m, #t ); 
	          } 
			( c:constantDeclarator[w] { ##.addChild(#c); } )+			
		)
	;
	
fieldDeclaration [Object w]
	:	#(	FIELD_DECL attributes[w]! modifiers[w] type[w]
			( variableDeclarator[w] )+
			
		)
	;
	
variableDeclarator [Object w]
	:	#(	VAR_DECLARATOR identifier[w]
			( variableInitializer[w] )? 
		)
	;
	
variableInitializer [Object w]
	:	#(	VAR_INIT
			(	expression[w]
			|	arrayInitializer[w]
			|	stackallocInitializer[w]
			)
		)
	;
		
methodDeclaration! [Object w]
	:	#(	METHOD_DECL a:attributes[w] m:modifiers[w] t:type[w] i:qualifiedIdentifier[w]
			b:methodBody[w]
			 ( p:formalParameterList[w] )? 
		) { 
			if (#p == null) #p = #( [FORMAL_PARAMETER_LIST, "FORMAL_PARAMETER_LIST"] ); 
			
			if (#i.getText() == "ToString" && #p.getFirstChild() == null)
			{
			  //TODO: keving: Note: Should generalize this, we also should trap equals, clone etc.
			  ## = #( [METHOD_DECL], #m, astFactory.dupTree(#t), #( [IDENTIFIER, "toString"] ), #p, #( [BLOCK], SmotherCheckedExceptions(#b, "RuntimeException") ));
			}
			else
			{
		      ## = #( [METHOD_DECL], #m, #t, #i, #p, #( [THROWS, "throws"], [IDENTIFIER, "Exception"] ), #b);
		      ##.setNextSibling(WrapMainMethod(#m, #t, #i, #p));   // Adds wrapper if this is Main
		    }
		  }
	;
	
memberName [Object w]
	:	qualifiedIdentifier[w]					// interfaceType^ DOT! identifier
//	|	identifier
	;
	
methodBody [Object w]
	:	body[w]
	;
	
formalParameterList [Object w]
	:	#(	FORMAL_PARAMETER_LIST 
			(	fixedParameters[w] (  parameterArray[w] )?
			|	parameterArray[w]
			)
		)
	;
	
fixedParameters [Object w]
	:	fixedParameter[w] (  fixedParameter[w] )*
	;
	
fixedParameter [Object w]
	:	#( 	PARAMETER_FIXED attributes[w]! 
			type[w] identifier[w] 
			( parameterModifier[w] )?
		)
	;
	
parameterModifier [Object w]
	: REF		
	| OUT		
	;
	
// In C#      public void fred(int[]... arg)
//
// In Java 	  public void fred(int... arg)
//
// So we strip the rank off here and the netTranslator has to
// make sure arg is an array.
parameterArray! [Object w]
	:	#(PARAMS attributes[w]!  t:type[w] i:identifier[w]   { ## = #( [PARAMS], StripOneRank(#t), #i); } 
		)
	;
	
propertyDeclaration! [Object w]
	:	#(	PROPERTY_DECL attributes[w] m:modifiers[w] t:type[w] id:qualifiedIdentifier[w] 
			a:accessorDeclarations[w] CLOSE_CURLY 
		)     { ## = #( [IDENTIFIER, "dummy"] );
			    // Take each getter/setter
                ASTNode gs = #a;
                
                while ( gs != null ) {
                  if (gs.getText() == "get") {
					AST new_id = astFactory.dupTree(#id);
					prependStringToId(new_id, "get");
                    ASTNode myGetter = #( [METHOD_DECL, "METHOD_DECL"], 
											astFactory.dupTree(#m), 
											astFactory.dupTree(#t), 
											new_id,
											#( [FORMAL_PARAMETER_LIST] ), #( [THROWS, "throws"], [IDENTIFIER, "Exception"] ),
											astFactory.dupTree(gs.getFirstChild()) );
                    if (## == null)
						## = myGetter;
				    else
				        ##.addChild(myGetter);
                  } else { 
					if (gs.getText() == "set") {
 						AST new_id = astFactory.dupTree(#id);
						prependStringToId(new_id, "set");
						ASTNode mySetter = #( [METHOD_DECL, "METHOD_DECL"], 
												astFactory.dupTree(#m), 
												#( [TYPE, "TYPE"],
													#( [VOID, "void"] ),
													#( [ARRAY_RANKS] ) ),
												new_id,
												#( [FORMAL_PARAMETER_LIST, "FORMAL_PARAMETER_LIST"],
													#( [PARAMETER_FIXED, "PARAMETER_FIXED"],
														astFactory.dupTree(#t),
														[IDENTIFIER, "value"] )), #( [THROWS, "throws"], [IDENTIFIER, "Exception"] ),
												astFactory.dupTree(gs.getFirstChild()) );
						if (## == null)
						    ## = mySetter;
						 else
						    ##.addChild(mySetter);
                    }                 
                  }
                  gs = (ASTNode) gs.getNextSibling();
                } 
                ## = (ASTNode) ##.getFirstChild();
			}
	;
	
accessorDeclarations [Object w]
	:	(	accessorDeclaration[w]
		)*
	;
	
accessorDeclaration [Object w]
	:	#( "get" attributes[w]! accessorBody[w] )
	|   #( "set" attributes[w]! accessorBody[w] )
	;
	
	
accessorBody [Object w]
	:	block[w]
	|   EMPTY_STMT
	;
	
eventDeclaration [Object w]
	:	#(/*evt:*/EVENT attributes[w] modifiers[w]  type[w]
			(	qualifiedIdentifier[w] 
				eventAccessorDeclarations[w]/*cly:*/CLOSE_CURLY 
			|	variableDeclarator[w] (  variableDeclarator[w] )* 
				
			)
		)
	;
	
eventAccessorDeclarations [Object w]
	:	addAccessorDeclaration[w] removeAccessorDeclaration[w]
	|	removeAccessorDeclaration[w] addAccessorDeclaration[w]
	;
	
addAccessorDeclaration [Object w]
	:	#( "add"    attributes[w] block[w] )
	;
	
removeAccessorDeclaration [Object w]
	:	#( "remove" attributes[w] block[w] )
	;


// for an index getter create get___idx()
// for the setter set___idx()
// I am trying to avoid clashes with possible property names (__idx would clash)
indexerDeclaration! [Object w]
	:	#(	INDEXER_DECL attributes[w] m:modifiers[w]
			t:type[w] ( interfaceType[w]  )? THIS
			f:formalParameterList[w]  a:accessorDeclarations[w] 
		/*cly:*/CLOSE_CURLY
		)		{ ## = #( [IDENTIFIER, "dummy"] );
			    // Take each getter/setter
                ASTNode gs = #a;
                
                while ( gs != null ) {
                  if (gs.getText() == "get") {
                    ASTNode myGetter = #( [METHOD_DECL, "METHOD_DECL"], 
											astFactory.dupTree(#m), 
											astFactory.dupTree(#t), 
											#( [IDENTIFIER, "get___idx"]),
											astFactory.dupTree(#f), #( [THROWS, "throws"], [IDENTIFIER, "Exception"] ),
											astFactory.dupTree(gs.getFirstChild()) );
				    ##.addChild(myGetter);
                  } else { 
					if (gs.getText() == "set") {
						ASTNode mySetter = #( [METHOD_DECL, "METHOD_DECL"], 
												astFactory.dupTree(#m), 
												#( [TYPE, "TYPE"],
													#( [VOID, "void"] ),
													#( [ARRAY_RANKS] ) ),
												#( [IDENTIFIER, "set___idx"]),
												astFactory.dupTree(#f), #( [THROWS, "throws"], [IDENTIFIER, "Exception"] ),
												astFactory.dupTree(gs.getFirstChild()) );
						##.addChild(mySetter);
                    }                 
                  }
                  gs = (ASTNode) gs.getNextSibling();
                } 
                ## = (ASTNode) ##.getFirstChild();
			}
	;
	
operatorDeclaration [Object w]
	:	(	#(	UNARY_OP_DECL attributes[w]! modifiers[w]
				type[w]  overloadableUnaryOperator[w]
				 formalParameterList[w]  
	 			operatorBody[w]
		 	)
		|	#(	BINARY_OP_DECL attributes[w]! modifiers[w]
				type[w]  overloadableBinaryOperator[w]
				 formalParameterList[w] 
		 		operatorBody[w]
			 )
		|   #(	CONV_OP_DECL attributes[w]! modifiers[w]
				( IMPLICIT | EXPLICIT ) type[w]	   
					formalParameterList[w] operatorBody[w]
			 ) 
		)
	;
	
overloadableUnaryOperator [Object w]
	:  UNARY_PLUS	
	|  UNARY_MINUS	
	|  LOG_NOT		
	|  BIN_NOT		
	|  INC			
	|  DEC			
	|  TRUE			
	|  FALSE		
	;
	
overloadableBinaryOperator [Object w]
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
	
operatorBody [Object w]
	:	body[w]
	;

constructorDeclaration [Object w]
	:!	#(	CTOR_DECL attributes[w]! m:modifiers[w] i:identifier[w]
			b:constructorBody[w]
			( p:formalParameterList[w] )? 
			( c:constructorInitializer[w] )? 
		) 
			{ 
				AST nbody = #( [BLOCK] );
				nbody.addChild(#c);
				nbody.addChild(#b.getFirstChild());
				if (#p == null)
					#p = #( [FORMAL_PARAMETER_LIST, "FORMAL_PARAMETER_LIST"] );
				## = #( CTOR_DECL, #m, #i, #p, #( [THROWS, "throws"], [IDENTIFIER, "Exception"] ), nbody);
			}		       
	;
	
constructorInitializer [Object w]
	:	(	#( BASE  ( es1:argumentList[w] )? ) { ##.setText("super"); if (#es1 == null) ##.addChild( #( [EXPR_LIST] ) ); }
		|	#( THIS  ( es2:argumentList[w] )? ) { ##.setText("this"); if (#es2 == null) ##.addChild( #( [EXPR_LIST] ) ); }
		)
	;
	
constructorBody [Object w]
	:	body[w]
	;

staticConstructorDeclaration! [Object w]
	:	#(	STATIC_CTOR_DECL attributes[w] modifiers[w] identifier[w] 
			b:staticConstructorBody[w]
		) { ## = #( [STATIC_CTOR_DECL], #( [BLOCK], SmotherCheckedExceptions(#b, "ExceptionInInitializerError") ) ); }
	;
	
staticConstructorBody [Object w]
	:	body[w]
	;
	
destructorDeclaration [Object w]
	:	#( 	DTOR_DECL attributes[w] modifiers[w] identifier[w] 
			destructorBody[w]
		)
	;
	
destructorBody [Object w]
	:	body[w]
	;

	
//
// A.2.7 Structs
//


// Convert to a class
// A struct instance is an object without identity
// We add a default constructor that does nothing. In C# a default 
// constructor is not allowed.  If a struct is declared without
// an explicit constructor call then struct fields will be initialized
// to defalt values,  but anyway program must assign to them before
// they can be used.
// [TODO]: What problems can happen when passed as parameter due to
// value vs ref semantics.
structDeclaration [Object w]
  { string saveClass = this.ClassInProcess; }
	:!	#( STRUCT attributes[w] mod:modifiers[w] id:identifier[w] { this.ClassInProcess = #id.getText(); }
			imps:structImplements[w]			
			#( TYPE_BODY mem:structMemberDeclarations[w, #id] CLOSE_CURLY  )
		) { ## = #( [CLASS, "class"], #mod, #id, #imps, #mem );
		    this.ClassInProcess = saveClass; }
	;

structImplements [Object w]
	:	#(	STRUCT_BASE ( type[w] )* )
	       { ##.setType(CLASS_BASE); }
	;	
	
structMemberDeclarations [Object w, ASTNode id]
		// Add Default Constructor
	:! { ASTNode ret = #( [MEMBER_LIST],
				 #( [CTOR_DECL],
						#( [MODIFIERS], [PUBLIC, "public"] ),
						astFactory.dupTree(id),
						#( [FORMAL_PARAMETER_LIST] ),
						#( [BLOCK] ) )
						 ); }
		#(	MEMBER_LIST
			(	s:structMemberDeclaration[w] { ret.addChild(#s); }
			|	p:preprocessorDirective[w, CodeMaskEnums.StructMemberDeclarations] { ret.addChild(#p); }
			)*
		) { ## = ret; }
	;
	
structMemberDeclaration [Object w]
	:	typeMemberDeclaration[w]
	;

	
//
// A.2.8 Arrays
//

rankSpecifiers [Object w]
	:	#(	ARRAY_RANKS
			( 	rankSpecifier[w]
			)*
		)
	;
	
rankSpecifier  [Object w]
	:	#( ARRAY_RANK 
			(COMMA 
			)* 			
		)
	;
	
arrayInitializer [Object w]
	:	#( ARRAY_INIT  ( variableInitializerList[w] )? CLOSE_CURLY!  ) 
	;
	
variableInitializerList [Object w]
	:	#( VAR_INIT_LIST v:arrayvariableInitializer[w] ( arrayvariableInitializer[w] )* ) {## = #v; }
	;

arrayvariableInitializer! [Object w]
	:	v:variableInitializer[w] {## = (ASTNode) #v.getFirstChild(); }
	;

// 
// A.2.9 Interfaces
//

interfaceDeclaration [Object w]
  { string saveClass = this.ClassInProcess; }
	:!	#(INTERFACE attributes[w] mod:modifiers[w] id:identifier[w] { this.ClassInProcess = #id.getText(); }
			imps:interfaceImplements[w]
			#( TYPE_BODY mem:interfaceMemberDeclarations[w] CLOSE_CURLY  )
		) { ## = #( [INTERFACE], #mod, #id, #imps, #mem );
		    this.ClassInProcess = saveClass; }
	;
	
interfaceImplements [Object w]
    : #( INTERFACE_BASE ( type[w] )* )
        { ##.setType(IMPLEMENTS_CLAUSE); ##.setText("implements"); }
	;
	
interfaceMemberDeclarations [Object w]
	:	#(	MEMBER_LIST
			(	interfaceMemberDeclaration[w]
			|	preprocessorDirective[w, CodeMaskEnums.InterfaceMemberDeclarations]
			)*
		)
	;
	
interfaceMemberDeclaration [Object w]
	:	(	methodDeclaration[w]
		|	propertyDeclaration[w]
		|	eventDeclaration[w]
		|	indexerDeclaration[w]
		)
	;
	
interfaceMethodDeclaration [Object w]
	:	#(	METHOD_DECL attributes[w]! modifiers[w] type[w] qualifiedIdentifier[w]
		    EMPTY_STMT 
			( f:formalParameterList[w] )?
		) { if (#f == null) ##.addChild( #( [FORMAL_PARAMETER_LIST, "FORMAL_PARAMETER_LIST"] )); } 
	;
	
interfacePropertyDeclaration [Object w]
	:	#(	PROPERTY_DECL attributes[w] modifiers[w] type[w] identifier[w]
			accessorDeclarations[w]/*cc:*/CLOSE_CURLY 
		)
	;
	
interfaceEventDeclaration [Object w]
	:	#(/*evt:*/EVENT attributes[w] modifiers[w] 
			type[w] variableDeclarator[w]		 
		)
	;
	
interfaceIndexerDeclaration [Object w]
	:	#(	INDEXER_DECL attributes[w] modifiers[w] type[w]/*t:*/THIS 
			formalParameterList[w] 
			accessorDeclarations[w]/*cc:*/CLOSE_CURLY 
		)
	;

	
//
//	A.2.10 Enums
//

enumDeclaration [Object w]
  { string saveClass = this.ClassInProcess; }
	:!	#( ENUM attributes[w] mod:modifiers[w] id:identifier[w] { this.ClassInProcess = #id.getText(); }
			basetype:enumImplements[w]
			#(  TYPE_BODY 
					mem:enumMemberDeclarations[w]			  
			    CLOSE_CURLY 
			)
		) { ## = #( [ENUM], #mod, #id, #( [IMPLEMENTS_CLAUSE] ), #mem);
		    this.ClassInProcess = saveClass; } 
	;

// keving: ignored in enumDeclaration
enumImplements [Object w]
  { ASTNode t = null; }
	:! #( ENUM_BASE ( gt:type[w] { t = #gt; } )? )
	   { if (t == null)
	        ## =  #( [TYPE], [INT, "int"], #( [ARRAY_RANKS] ) );
	     else
	        ## = #gt; }
	;

// Convert the declarations to a simple list,  match their intended value to their ordinal position by adding in
// dummy enums	
enumMemberDeclarations! [Object w]
 { SortedList ExplicitEnums = new SortedList();
   ArrayList ImplicitEnums = new ArrayList();
   int dummyCounter = 0;
 }
	: #( MEMBER_LIST ( enumMemberDeclaration[w, ExplicitEnums, ImplicitEnums] )* ) 
	{
	   ## = #(MEMBER_LIST);
	   int ord = 0;
	   foreach (DictionaryEntry de in ExplicitEnums)
	   {
	      // entries are sorted by enum value
	      int enumValue = (int) de.Key;
	      ASTNode enumAST = (ASTNode) de.Value;
	      while (ord < enumValue)
	      {  
	         // We need some padding here
	         if (ImplicitEnums.Count > 0)
	         {
	            ##.addChild((ASTNode) ImplicitEnums[0]);
	            ImplicitEnums.RemoveAt(0);
	         }
	         else
	         {
	            string dummyEnum = "__dummyEnum" + dummyCounter;
	            dummyCounter++;
	            ##.addChild(#([IDENTIFIER, dummyEnum]));
	         }
	         ord++;
	      }    
	      ##.addChild(enumAST);
	      ord++;
	   }
	   // Add implicit enums that haven't yet been accounted for
	   foreach (ASTNode id in ImplicitEnums)
	      ##.addChild((ASTNode) #id);

	}
	;
		
enumMemberDeclaration! [Object w, SortedList e, ArrayList i]
 { bool init = false; }
	:	#( id:IDENTIFIER { fixBrokenIds(#id); } attributes[w]
				( c:constantExpression[w] 
				    { // If constantExpression is #(EXPR #( [INT_LITERAL, xxx] ) ) 
				      // then we maintain its value, otherwise print a warning and
				      // give it next available slot
				      bool hasValue = false;
				      int intValue = 0;
				      if (#c.Type == EXPR)
				      {
				         if (#c.getFirstChild().Type == INT_LITERAL)
				         {
				            // Assigned value
				            String strValue = #c.getFirstChild().getText();
				            if ( strValue.StartsWith("0x", StringComparison.OrdinalIgnoreCase)) {
                              intValue = Int32.Parse(strValue.Substring(2), NumberStyles.HexNumber);
                            }
							else {
				              intValue = Int32.Parse(strValue);
				            }
				            if (!e.Contains(intValue))
				               hasValue = true;
				            else
				               Console.Error.WriteLine("ERROR -- (enumMemberDeclaration): repeated enum value: " + intValue);
				         }
				      }
				      if (hasValue)
				      {
				         init = true;
				         e[intValue] = #id;
				      }
				      else
				         Console.Out.WriteLine("WARNING -- (enumMemberDeclaration): Ignoring assigned value of " + #id.getText());
				    }
				   )?
				{ if (!init)
				    i.Add(#id);
				}
		)
 	;


//
// A.2.11 Delegates
//

delegateDeclaration [Object w]
	:	#(/*dlg:*/DELEGATE attributes[w] modifiers[w] 
			type[w] identifier[w] ( f:formalParameterList[w] )? 
		) { if (#f == null) ##.addChild( #( [FORMAL_PARAMETER_LIST, "FORMAL_PARAMETER_LIST"] )); } 
	;
	

//
// A.2.12 Attributes
//

globalAttributes [Object w]
	:	#(	GLOBAL_ATTRIBUTE_SECTIONS 
			(	globalAttributeSection[w]
			|	preprocessorDirective[w, CodeMaskEnums.GlobalAttributes]
			)*
		)
	;
	
globalAttributeSection [Object w]
	:	#(/*sect:*/GLOBAL_ATTRIBUTE_SECTION  
			( attribute[w] )+  
		)
	;

attributes [Object w]
	:	#(	ATTRIBUTE_SECTIONS 
			(	attributeSection[w]
			|	preprocessorDirective[w, CodeMaskEnums.Attributes]
			)*
		)
	;
	
attributeSection [Object w]
	:	#(/*sect:*/ATTRIBUTE_SECTION  ( attributeTarget[w] )?
			( attribute[w] )+  
		)
	;
	
attributeTarget[Object w]
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

attribute [Object w]
	:	#( ATTRIBUTE typeName[w] attributeArguments[w] )
	;
	
attributeArguments [Object w]
	:	( positionalArgumentList[w] )? ( namedArgumentList[w] )? 
	;
	
positionalArgumentList [Object w]
	:	#(	POSITIONAL_ARGLIST positionalArgument[w]
			( positionalArgument[w] )* 
		)
	;
	
positionalArgument [Object w]
	:	#( POSITIONAL_ARG attributeArgumentExpression[w] )
	;
	
namedArgumentList [Object w]
	:	#(	NAMED_ARGLIST namedArgument[w]
			( namedArgument[w] )* 
		)
	;
	
namedArgument [Object w]
	:	#( NAMED_ARG identifier[w] attributeArgumentExpression[w] )
	;
	
attributeArgumentExpression [Object w]
	:	#( ATTRIB_ARGUMENT_EXPR expression[w] )
	;

//
// A.3 Grammar extensions for unsafe code
// 

fixedPointerDeclarator [Object w]
	:	#( PTR_DECLARATOR identifier[w] fixedPointerInitializer[w] )
	;
	
fixedPointerInitializer [Object w]
	:	#(	PTR_INIT
			(/*b:*/BIN_AND variableReference[w]
			|	expression[w]
			)
		)
	;	
	
stackallocInitializer [Object w]
	:	#(/*s:*/STACKALLOC unmanagedType[w]  expression[w]  )
	;

//======================================
// Preprocessor Directives
//======================================

justPreprocessorDirectives [Object w]
	:	#(	PP_DIRECTIVES 
			(	preprocessorDirective[w, CodeMaskEnums.PreprocessorDirectivesOnly] 
			)* 
		)
	;
	
preprocessorDirective [Object w, CodeMaskEnums codeMask]
	:!	#(PP_DEFINE   i:PP_IDENT  {defines[#i.getText()] = true;} )
	|!	#(/*u1:*/PP_UNDEFINE i2:PP_IDENT  {defines.Remove(#i2.getText()); } )
	|!	#(/*l1:*/PP_LINE    
			(/*l2:*/DEFAULT   
			|/*l3:*/PP_NUMBER  (/*l4:*/PP_FILENAME  )? 
			)
		)
	|!	#(/*e1:*/PP_ERROR    ppMessage[w] )
	|!	#(/*w1:*/PP_WARNING  ppMessage[w] )
	|	regionDirective[w, codeMask]
	|	conditionalDirective[w, codeMask]
	;
	
regionDirective! [Object w, CodeMaskEnums codeMask]
	:	#(PP_REGION  ppMessage[w] b:directiveBlock[w, codeMask]
			#(PP_ENDREGION  ppMessage[w] )
		) { ## = #b; }
	;

conditionalDirective! [Object w, CodeMaskEnums codeMask] 
  { ASTNode ret = null;
    bool c = false; }
	:	#(PP_COND_IF         c = preprocessExpression[w]  th:directiveBlock[w, codeMask] { if (c) ret = #th; }
			( #(PP_COND_ELIF  c = preprocessExpression[w]  ce:directiveBlock[w, codeMask] ) { if (c && ret == null) ret = #ce; } )*
			( #(PP_COND_ELSE  el:directiveBlock[w, codeMask] ) { if (ret == null) ret = #el; } )?
		  PP_COND_ENDIF     
		) { ## = ret; }
	;

directiveBlock [Object w, CodeMaskEnums codeMask]
	:	#(	PP_BLOCK
			(	{ NotExcluded(codeMask, CodeMaskEnums.UsingDirectives) }?				usingDirective[w]
			|	{ NotExcluded(codeMask, CodeMaskEnums.GlobalAttributes) }?				globalAttributeSection[w]
			|	{ NotExcluded(codeMask, CodeMaskEnums.Attributes) }?					attributeSection[w]
			|	{ NotExcluded(codeMask, CodeMaskEnums.NamespaceMemberDeclarations) }?	namespaceMemberDeclaration[w, null, null]
			|	{ NotExcluded(codeMask, CodeMaskEnums.ClassMemberDeclarations) }?		classMemberDeclaration[w]
			|	{ NotExcluded(codeMask, CodeMaskEnums.StructMemberDeclarations) }?		structMemberDeclaration[w]
			|	{ NotExcluded(codeMask, CodeMaskEnums.InterfaceMemberDeclarations) }?	interfaceMemberDeclaration[w]
			|	{ NotExcluded(codeMask, CodeMaskEnums.Statements) }?					statement[w]
			|	preprocessorDirective[w, codeMask]
			)*
		) {## = (ASTNode) ##.getFirstChild(); }
	;
	
ppMessage [Object w]
	:	#(	PP_MESSAGE
			(/*m1:*/PP_IDENT 		
			|/*m2:*/PP_STRING 		
			| /*m3:*/PP_FILENAME 		
			| /*m4:*/PP_NUMBER 		
			)*
		)
	;

preprocessExpression [Object w] returns [bool v]
  { v = false; }
	:	#( PP_EXPR v = preprocessExpr[w] )
	;

preprocessExpr [Object w] returns [bool v]
  { bool v1, v2;
    v = false;
  }
	:	#( LOG_OR    v1 = preprocessExpr[w]  v2 = preprocessExpr[w] )   { v = v1 | v2; }
	|	#( LOG_AND   v1 = preprocessExpr[w]  v2 = preprocessExpr[w] )   { v = v1 & v2; }
	|	#( EQUAL     v1 = preprocessExpr[w]  v2 = preprocessExpr[w] )   { v = v1 == v2; }
	|	#( NOT_EQUAL v1 = preprocessExpr[w]  v2 = preprocessExpr[w] )   { v = v1 != v2; }
	|	v = preprocessPrimaryExpression[w]
	;
	
preprocessPrimaryExpression [Object w] returns [bool v]
  { bool r;
    v = false;
  }
	:  i:PP_IDENT { v = (defines[#i.getText()] == null?false:(bool)defines[#i.getText()]); // Should look up in symbol table! 
	            } 		
	|  TRUE     { v = true; }			
	|  FALSE    { v = false; }		
	|	#( LOG_NOT 	 r = preprocessPrimaryExpression[w] )  { v = !r; }
	|	#( PAREN_EXPR  v = preprocessExpr[w]  )
	;
