header {
	using System.Collections;
	using System.IO;
	using System.Xml;
	using TokenStreamHiddenTokenFilter	= antlr.TokenStreamHiddenTokenFilter;
}

options {
	language =  "CSharp";
	namespace = "RusticiSoftware.Translator";
}

/** Java 1.3 AST Pretty Printer
 *
 * Author: Kevin Glynn <kevin.glynn@scorm.com>
 *
 * This grammar is based on the java tree walker included in ANTLR examples
 *
 */
 
class JavaPrettyPrinter extends TreeParser("RusticiSoftware.Translator.JavaTreeParser");

options {
	importVocab = CSharpJava;
	buildAST = false;
}

{

	private int indentLevel = 0;
	private const string INDENT = "    ";
	private bool indented = false;
	private bool doIndent = true;
    private const int MAX_TOKEN_TYPE=350; // imprecise but big enough
    private TokenStreamHiddenTokenFilter filter;
    private XmlTextWriter enumXmlWriter;
    private ArrayList enumMembers = new ArrayList();
    
	/** walk list of hidden tokens in order, printing them out */
	public void dumpHidden(TextWriter w, antlr.IHiddenStreamToken t) {
	  for ( ; t!=null ; t=filter.getHiddenAfter(t) ) {
	    w.Write(t.getText());
	  }
	}

   	/// <summary>
	/// Prints the text of the specified AST node
	/// </summary>
	/// <param name="w">The output destination.</param>
	/// <param name="node">The AST node to print.</param>
    private void Print(TextWriter w, AST node)
    {
    	Print(w, node, null);
    }

	/// <summary>
	/// Prints the text
	/// </summary>
	/// <param name="w">The output destination.</param>
	/// <param name="node">The AST node to print.</param>
    private void Print(TextWriter w, string text)
    {
    	Print(w, null, text);
    }


	/// <summary>
	/// Prints the text of the AST node if it exists, then the text if it exists
	/// </summary>
	/// <param name="w">The output destination.</param>
	/// <param name="node">The AST node to print.</param>
    private void Print(TextWriter w, AST node, string text)
    {
		if (doIndent && !indented) {
			PrintIndent(w);
		}
    	if (node != null)
    	{
    		w.Write(node.getText());
    	}
    	if (text != null)
    	{
    		w.Write(text);
    	}
    	if (node != null)
    	{
    	    // disable for now
    		// dumpHidden(w, ((antlr.CommonASTWithHiddenTokens)node).getHiddenAfter());
    	}
    }
    
    private void PrintNL(TextWriter w)
    {
		w.Write("\n");	// Should we take newline from environment?
		if (doIndent) indented = false;
    }
    
    private void PrintNLIfReq(TextWriter w)
    {
		if (doIndent && indented)
		   PrintNL(w);
    }
    
    
    private void PrintIndent(TextWriter w)
    {
		for (int i = 0; i < indentLevel; i++) {
			w.Write(INDENT);
		}
		if (doIndent) indented = true;
    }
    
    private void WriteStartEnum(AST node)
    {
		if (enumXmlWriter != null)
		{
			enumXmlWriter.WriteStartElement("enum");
			enumXmlWriter.WriteAttributeString("id", node.getText());
		}
    }
    
    private void WriteEndEnum()
    {
		if (enumXmlWriter != null)
		{
			enumXmlWriter.WriteEndElement();
		}
    }
    
    private void WriteEnumMembers()
    {
		if (enumXmlWriter != null)
		{
			int num = 0;
			foreach (AST node in enumMembers)
			{
				enumXmlWriter.WriteStartElement("member");
				enumXmlWriter.WriteAttributeString("id", node.getText());
				enumXmlWriter.WriteAttributeString("value", num.ToString());
				enumXmlWriter.WriteEndElement();
				num++;
			}
		}
    }
    
    // keving:  Found this precedence table on the ANTLR site.
    
    /** Encodes precedence of various operators; indexed by token type.
     *  If precedence[op1] > precedence[op2] then op1 should happen
     *  before op2;
     */
    private static int[] precedence = new int[MAX_TOKEN_TYPE];

    static JavaPrettyPrinter()
    {
        for (int i=0; i<precedence.Length; i++) {
            // anything but these operators binds super tight
            // for example METHOD_CALL binds tighter than PLUS
            precedence[i] =  int.MaxValue;
        }
        precedence[ASSIGN] = 1;
        precedence[PLUS_ASSIGN] = 1;
        precedence[MINUS_ASSIGN] = 1;
        precedence[STAR_ASSIGN] = 1;
        precedence[DIV_ASSIGN] = 1;
        precedence[MOD_ASSIGN] = 1;
        precedence[SHIFTR_ASSIGN] = 1;
        //precedence[BSR_ASSIGN] = 1;
        precedence[SHIFTL_ASSIGN] = 1;
        precedence[BIN_AND_ASSIGN] =1;
        precedence[BIN_XOR_ASSIGN] = 1;
        precedence[BIN_OR_ASSIGN] = 1;

        precedence[QUESTION] = 2;

        precedence[LOG_OR] = 3;

        precedence[LOG_AND] = 4;

        precedence[BIN_OR] = 5;

        precedence[BIN_XOR] = 6;

        precedence[BIN_AND] = 7;

        precedence[NOT_EQUAL] = 8;
        precedence[EQUAL] = 8;

        precedence[LTHAN] = 9;
        precedence[GTHAN] = 9;
        precedence[LTE] = 9;
        precedence[GTE] = 9;
        precedence[INSTANCEOF] = 9;

        precedence[SHIFTL] = 10;
        precedence[SHIFTR] = 10;
        //precedence[BSR] = 10;

        precedence[PLUS] = 11;
        precedence[MINUS] = 11;

        precedence[DIV] = 12;
        precedence[MOD] = 12;
        precedence[STAR] = 12;

        precedence[INC] = 13;
        precedence[DEC] = 13;
        precedence[BIN_NOT] = 13;
        precedence[LOG_NOT] = 13;
        precedence[UNARY_MINUS] = 13;
        precedence[UNARY_PLUS] = 13;

        precedence[POST_INC_EXPR] = 14;
        precedence[POST_DEC_EXPR] = 14;   
    }


    // Compares precedence of op1 and op2. 
    // Returns -1 if op2 < op1
    //	        0 if op1 == op2
    //          1 if op2 > op1
    public static int comparePrecedence(AST op1, AST op2) {
		// A gross hack for "instanceof" (no longer necessary with C# front end :-))
		// if (op1.getText() == "instanceof")
		//    precedence[op1.Type] = 9;
		// if (op2.getText() == "instanceof")
		//    precedence[op2.Type] = 9;
		   
        return Math.Sign(precedence[op2.Type]-precedence[op1.Type]);
    }


}



compilationUnit [TextWriter w, XmlTextWriter enumXmlWriter, TokenStreamHiddenTokenFilter f]
 { filter = f; this.enumXmlWriter = enumXmlWriter; }
	:	#( COMPILATION_UNIT 
			packageDefinition[w]
			useDefinitions[TextWriter.Null]    // No output for uses
			importDefinitions[w]
			(typeDefinition[w])*
		)
	;

packageDefinition [TextWriter w]
	:	#( pkg:PACKAGE_DEF	({ Print(w, #pkg, " "); } identifier[w] { Print(w, ";"); PrintNL(w); })? )
	;

useDefinitions [TextWriter w]
	:	#( USING_DIRECTIVES
			(useDefinition[w])*
		)
	;
	
useDefinition [TextWriter w]
	:	#( USING_NAMESPACE_DIRECTIVE	
	       identifier[w]		
	       )
	|   #(	USING_ALIAS_DIRECTIVE     	
			alias:identifier[w] 					
			pna:identifier[w] 			
		)
	;
	
importDefinitions [TextWriter w]
	:	#( IMPORTS 
			( { PrintNL(w); } (importDefinition[w])+ )?
		)   { PrintNL(w); }
	;	
	
importDefinition [TextWriter w]
	:	#( imp:IMPORT				{ Print(w, #imp, " "); }
	          identifier[w]		    { Print(w, ";"); PrintNL(w); }
	       )
	;

typeDefinition [TextWriter w]
	:	#(cl:CLASS			
			modifiers[w] 
			id:IDENTIFIER				{ Print(w, "class "); Print(w, #id, " "); }
			extendsClause[w] 
			implementsClause[w]     { PrintNL(w); Print(w, "{"); PrintNL(w); indentLevel++; }
			objBlock[w]             { indentLevel--; Print(w, "}"); PrintNL(w); }              
			)
	|	#(INTERFACE 
			modifiers[w] 
			ifid:IDENTIFIER 				{ Print(w, "interface "); Print(w, #ifid, " "); }
			implementsClause[w]		{ PrintNL(w); Print(w, "{"); PrintNL(w); indentLevel++; } 
			interfaceBlock[w]       { indentLevel--; Print(w, "}"); PrintNL(w); }
			)	
	|	#(ENUM 
			modifiers[w] 
			enmid:IDENTIFIER 				{ Print(w, "enum "); Print(w, #enmid, " "); WriteStartEnum(#enmid); }
			implementsClause[w]		{ PrintNL(w); Print(w, "{"); PrintNL(w); indentLevel++; } 
			enumBlock[w]			{ indentLevel--; Print(w, "}"); PrintNL(w); WriteEndEnum(); }
			)
	|	#(ann:ANNOTATION			
			modifiers[w] 
			annid:IDENTIFIER				{ Print(w, "@interface "); Print(w, #annid, " "); PrintNL(w); Print(w, "{"); PrintNL(w); indentLevel++;}
			objBlock[w]             { indentLevel--; Print(w, "}"); PrintNL(w); }              
			)
	;

typeSpec [TextWriter w]
	:	#(TYPE 
			( 	identifier[w]
			| 	builtInType[w]
			)
			rankSpecifiers[w]		
	     )
	;
	
rankSpecifiers [TextWriter w]
	:	#(	ARRAY_RANKS
			( 	rankSpecifier[w]
			)*
		)
	;
	
rankSpecifier  [TextWriter w]
	:	#(ARRAY_RANK	
			( COMMA  // Notice, we ignore dimensions.
			)* 			
		) { Print(w, "[]"); }
	;
	
typeSpecArray [TextWriter w]
	:	#( ARRAY_DECLARATOR 
			typeSpecArray[w]				{ Print(w, "[]"); }
			)
	|	type[w]
	;

type [TextWriter w]
	:	identifier[w]
	|	builtInType[w]
	;

builtInType [TextWriter w]
    :   tvo:VOID				{ Print(w, #tvo); }
    |   tbo:BOOL				{ Print(w, #tbo); }
    |   tst:STRING				{ Print(w, #tst); }
    |   tby:SBYTE				{ Print(w, #tby); }
    |   tch:"char"				{ Print(w, #tch); }
    |   tsh:"short"				{ Print(w, #tsh); }
    |   tin:"int"				{ Print(w, #tin); }
    |   tfl:"float"				{ Print(w, #tfl); }
    |   tlo:"long"				{ Print(w, #tlo); }
    |   tdo:"double"			{ Print(w, #tdo); }
    |   tuby: UBYTE				{ Print(w, #tuby); }
    |   tudec: DECIMAL			{ Print(w, #tudec); }
    |   tuint: UINT				{ Print(w, #tuint); }
    |   tulng: ULONG			{ Print(w, #tulng); }
    |   tush: USHORT			{ Print(w, #tush); }
    |   tb: BYTE                { Print(w, #tb); }
    ;

modifiers [TextWriter w]
	:	#( MODIFIERS (modifier[w]     { Print (w, " "); } 
			)* )
	;

modifier [TextWriter w]
    :   mpr:"private"				{ Print(w, #mpr); }
    |   mpu:"public"				{ Print(w, #mpu); }
    |   mpt:"protected"				{ Print(w, #mpt); }
    |   mst:"static"				{ Print(w, #mst); }
    |   mtr:"transient"				{ Print(w, #mtr); }
    |   mfi:FINAL					{ Print(w, #mfi); }   
    |   mab:ABSTRACT				{ Print(w, #mab); }
    |   mna:"native"				{ Print(w, #mna); }
    |   mth:"threadsafe"			{ Print(w, #mth); }
    |   msy:"synchronized"			{ Print(w, #msy); }
    |   mco:"const"					{ Print(w, #mco); }
    |   mvo:"volatile"				{ Print(w, #mvo); }
	|	msf:"strictfp"				{ Print(w, #msf); }
    ;

extendsClause [TextWriter w]
    //OK, OK, really we can only extend 1 class, but the tree stores a list so ....
	:	#(EXTENDS_CLAUSE 
			( { Print(w, "extends "); } identifier[w] ({ Print(w, ", "); } identifier[w])* { Print(w, " "); } )? 
			)
	;

implementsClause [TextWriter w]
 	:	#(IMPLEMENTS_CLAUSE 
 			( { Print(w, "implements "); } identifier[w] ({ Print(w, ", "); } identifier[w])* { Print(w, " "); } )? 
 			)
	;


interfaceBlock [TextWriter w]
	:	#(	MEMBER_LIST
			(	methodDecl[w] { Print(w, ";"); PrintNL(w); }
			|	variableDef[w] { Print(w, ";"); PrintNL(w); }
			|	typeDefinition[w] 
			)*
		)
	;
	
objBlock [TextWriter w]
	:	#(	MEMBER_LIST
			(
			(	{ PrintNL(w); } ctorDef[w] 
			|	{ PrintNL(w); } methodDef[w] 
			|	variableDef[w] { Print(w, ";"); }
			|	{ PrintNL(w); } typeDefinition[w] 
			|	{ PrintNL(w); } #(STATIC_CTOR_DECL { Print(w, "static"); PrintNL(w); } 
						slist[w] )
			|	{ PrintNL(w); } #(INSTANCE_INIT 
					slist[w] )
			) { PrintNLIfReq(w); } 
			)*
		) 
	;

// This enumblock is from Java 1.3,  in theory enums can have methods, nested enums, ....
enumBlock [TextWriter w]
 { enumMembers.Clear(); }
	: #( MEMBER_LIST ( alt1:IDENTIFIER { Print(w, #alt1); enumMembers.Add(#alt1); } ( alts:IDENTIFIER { Print(w, ", "); Print(w, #alts); enumMembers.Add(#alts); } )* { PrintNL(w); WriteEnumMembers(); } )? )
	;
	
ctorDef [TextWriter w]
	:	#(CTOR_DECL 
			modifiers[w]	
			methodHead[w]	 
			(slist[w])?)	
	;

methodDecl [TextWriter w]
	:	#(METHOD_DECL 
			modifiers[w] 
			typeSpec[w]						{ Print(w, " "); }  
			methodHead[w])
	;

methodDef [TextWriter w]
	:	#(METHOD_DECL						
			modifiers[w] 
			typeSpec[w]						{ Print(w, " "); }
			methodHead[w]					
			(slist[w])?						 
			)
	;

variableDef [TextWriter w]
	:	#(FIELD_DECL
			modifiers[w] 
			typeSpec[w]					{ Print(w, " "); }
			variableDeclarator[w] ( {Print(w, ", "); } variableDeclarator[w])*
			//varInitializer[w]
		) 
	;

parameterDef [TextWriter w]
	:	#(PARAMETER_FIXED  
			typeSpec[w]					{ Print(w, " "); }
			id:IDENTIFIER					{ Print(w, #id); }
			)
	|   #(PARAMS typeSpec[w] { Print(w, "... "); } ids:IDENTIFIER { Print(w, #ids); } )
	;

objectinitializer [TextWriter w]
	:	#(INSTANCE_INIT 
					slist[w]  )
	;

variableDeclarator [TextWriter w]
	:	#( VAR_DECLARATOR 
				id:IDENTIFIER	{ Print(w, #id); }
				(varInitializer[w])?
		)
//	|	LBRACK variableDeclarator[w]	{ Print(w, "[]"); }
	;

varInitializer [TextWriter w]
	:	#(VAR_INIT				     { Print(w, " = "); } 
			initializer[w])   
	;

initializer [TextWriter w]
	:	expression[w]
	|	arrayInitializer[w]
	;

arrayInitializer [TextWriter w]
	:	#(ARRAY_INIT 
			{ Print(w, "{"); } 
				( initializer[w] ( { Print(w, ", "); } initializer[w] )* )? 
			{ Print(w, "}"); } 
	     )
	;

methodHead [TextWriter w]
 	:	id:IDENTIFIER							{ Print(w, #id); }
		#( FORMAL_PARAMETER_LIST						
			{ Print(w, "("); } 
				( parameterDef[w] ( { Print(w, ", "); } parameterDef[w] )* )? 
			{ Print(w, ") "); } 
			)			
		( throwsClause[w])? { PrintNL(w); }
	;

throwsClause [TextWriter w]
 	:	#( th:"throws"						{ Print(w, #th, " "); } 
			( identifier[w] ( { Print(w, ", "); } identifier[w] )* )?
		)
	;

identifier [TextWriter w]
	:   id:IDENTIFIER						{ Print(w, #id); }
	|	#( DOT id1:IDENTIFIER { Print(w, #id1); Print(w, "."); } identifier[w]  )      
	;

identifierStar [TextWriter w]
	:	id:IDENTIFIER										{ Print(w, #id); }
	|   st:STAR												{ Print(w, "."); Print(w, #st); }  
	|	#( DOT id1:IDENTIFIER { Print(w, #id1); Print(w, "."); } identifier[w]  ) 
	;

slist [TextWriter w]
	:	#( BLOCK { Print(w, "{"); PrintNL(w); indentLevel++; } (stat[w])*  { indentLevel--; Print(w, "}"); PrintNL(w); } )
	|   EMPTY_STMT { Print(w, ";"); PrintNL(w); }
	;

// Like a slist[] but we don't indent.  Appears in switch alternatives
statementList [TextWriter w]
	:	#( STMT_LIST (stat[w])* )
	;

stat [TextWriter w]
    :(
		typeDefinition[w]
	|	variableDef[w]							{ Print(w, ";"); }
	|	#(EXPR_STMT expression[w])				{ Print(w, ";"); }
	|	#(LABELED_STAT id:IDENTIFIER	{ Print(w, #id, ": "); } stat[w])
	|	#(lif:IF								{ Print(w, #lif, " ("); }
			expression[w]						{ Print(w, ")"); PrintNL(w); }
			stat[w]								
			( #(ELSE									{ Print(w, "else"); PrintNL(w); } 
				  stat[w])								
				)? 
			)
	|	#(	fo:"for"									{ Print(w, #fo, " ("); }
			#(FOR_INIT (variableDef[w])* (expression[w] ( { Print(w, ", "); } expression[w])* )?) { Print(w, "; "); }
			#(FOR_COND (expression[w])?)			{ Print(w, "; "); }
			#(FOR_ITER (expression[w] ( { Print(w, ", "); } expression[w])* )?)					{ Print(w, ")"); PrintNL(w); }
			stat[w]										
		)
	|	#(fe:"foreach"									{ Print(w, "for ("); }
			variableDef[w]								{ Print(w, " : "); }
			expression[w]								{ Print(w, ")"); PrintNL(w); }
			stat[w]										
			)
	|	#(wh:"while"									{ Print(w, #wh, " ("); }
			expression[w]								{ Print(w, ")"); PrintNL(w); }
			stat[w]										
			)
	|	#(dd:"do"										{ Print(w, #dd); PrintNL(w); } 
			stat[w]										{ Print(w, "while ("); }
			expression[w]								{ Print(w, ");"); }
			)
	|	#(br:"break"	{ Print(w, #br); } ( { Print(w, " "); } IDENTIFIER)?			{ Print(w, ";"); } )
	|	#(co:"continue" { Print(w, #co); } ( { Print(w, " "); } IDENTIFIER)?			{ Print(w, ";"); } )
	|	#(re:"return"	{ Print(w, #re); } ( { Print(w, " "); } expression[w])? { Print(w, ";"); } )
	|	#(sw:"switch"			{ Print(w, #sw, " ("); }
			expression[w]		{ Print(w, ")"); PrintNL(w); Print(w, "{"); indentLevel++; PrintNL(w); }
			(caseGroup[w])*		
			)					{ indentLevel--; Print(w, "}"); }
	|	#(th:"throw"		{ Print(w, #th, " "); } expression[w] { Print(w, ";"); } )
	|	#(sy:"synchronized"			{ Print(w, #sy, " ("); } 
				expression[w]		{ Print(w, ")"); PrintNL(w); }
				stat[w]				
				)
	|	tryBlock[w]
	|	slist[w] // nested SLIST  (keving:  should this be surrounded by braces?)
    // uncomment to make assert JDK 1.4 stuff work
    // |   #("assert" expression[w] (expression[w])?)
	|	ctorCall[w]							{ Print(w, ";"); }		
	) { PrintNLIfReq(w); }
	;

caseGroup [TextWriter w]
	:	#(SWITCH_SECTION (#(ca:"case"				{ Print(w, #ca, " "); }
							expression[w])		{ Print(w, ":"); PrintNL(w); indentLevel++; }
						  | de:"default"			{ Print(w, #de, ":"); PrintNL(w); indentLevel++; } )+ 
					  statementList[w] )		{ indentLevel--; }
	;

tryBlock [TextWriter w]
	:	#( tr:"try"				{ Print(w, #tr);  PrintNL(w); }
			slist[w]			 
			(handler[w])* 
			(#(fi:"finally"     { Print(w, #fi); PrintNL(w); }
				slist[w]		
				))? 
			)
	;

handler [TextWriter w]
	:	#( ca:"catch"				{ Print(w, #ca, " ("); }
			( typeSpec[w] | variableDef[w])			{ Print(w, ")"); PrintNL(w); }
			slist[w]				
			)
	;

elist [TextWriter w]
	:	#( EXPR_LIST
			( expression[w] ( { Print(w, ", "); } expression[w] )* )?
		)
	;

expression [TextWriter w]
	:	#(EXPR expr[w])
	;

expr [TextWriter w]
		// QUESTION is right associative in C# and left-associative in Java, but we always parenthesize :-)
	:	#(QUESTION { Print(w, "( "); } expr[w] { Print(w, " ? "); } expr[w] { Print(w, " : "); } expr[w] { Print(w, " )"); })	// trinary operator
        // binary operators...
	|   (ASSIGN|PLUS_ASSIGN|MINUS_ASSIGN|STAR_ASSIGN|DIV_ASSIGN
        |MOD_ASSIGN|SHIFTR_ASSIGN|BSR_ASSIGN|SHIFTL_ASSIGN|BIN_AND_ASSIGN
        |BIN_XOR_ASSIGN|BIN_OR_ASSIGN|LOG_OR|LOG_AND|BIN_OR|BIN_XOR|BIN_AND|NOT_EQUAL
        |EQUAL|LTHAN|GTHAN|LTE|GTE|SHIFTL|SHIFTR|BSR|PLUS|MINUS|DIV|MOD|STAR|INSTANCEOF
		)
        {
			AST op = #expr;
			AST left = op.getFirstChild();
			AST right = left.getNextSibling();
			bool lp = false;
			bool rp = false;
			switch ( comparePrecedence(op,left) ) 
			{
				case -1 :
					lp = true;
					break;
				case 0 :
					if (op.Type == ASSIGN) lp = true;   // ASSIGN/QUESTION is right associative in C#
					break;
				case 1:
					break;
			}
				
			switch ( comparePrecedence(op,right) ) 
			{
				case -1: 
					rp = true;
					break;
				case 0:
					if (op.Type != ASSIGN) rp = true;   // All operators except ASSIGN/QUESTION are left associative in C#
					break;
				case 1:
					break;
			}
				
			if ( lp ) Print(w, "(");
			expr(left,w);
			if ( lp ) Print(w, ")");

            Print(w, " "+#op.getText()+" ");

			if ( rp ) Print(w, "(");
			expr(right,w); // manually invoke
			if ( rp ) Print(w, ")");
        }

    |   (INC|DEC|BIN_NOT|LOG_NOT|UNARY_MINUS|UNARY_PLUS)
        {
			AST op = #expr;
			AST opnd = op.getFirstChild();
			bool p = false;
			if ( comparePrecedence(op,opnd) == -1) {
				p = true;
			}
			Print(w, op.getText());
			if ( p ) Print(w, "(");
			expr(opnd, w);
			if ( p ) Print(w, ")");
        }

    |   #( POST_INC_EXPR expr[w] {Print(w, "++");} )
    |   #( POST_DEC_EXPR expr[w] {Print(w, "--");} )
    |	primaryExpression[w]
	;
	


primaryExpression [TextWriter w]
    :   id:IDENTIFIER								{ Print(w, #id); }
    |   #(	MEMBER_ACCESS_EXPR		
			(	expr[w]							{ Print(w, "."); } 
				(	did:IDENTIFIER					{ Print(w, #did); }
				|	arrayIndex[w]
				|	dth:"this"					{ Print(w, #dth); }
				|	dcl:"class"					{ Print(w, #dcl); }
				|	#( dne:"new" dni:IDENTIFIER { Print(w, #dne, " "); Print(w, dni, "("); } elist[w] { Print(w, ")"); } )
				|   dsu:"super"					{ Print(w, #dsu); }
				)
			|	{ Print(w, "."); } #(ARRAY_DECLARATOR typeSpecArray[w] { Print(w, "[]"); }  )
			|	{ Print(w, "."); } builtInType[w] (ddcl:"class"  { Print(w, #ddcl); } )?
			)
		)
	|	arrayIndex[w]
	|	#(INVOCATION_EXPR primaryExpression[w]  { Print(w, "("); } elist[w] { Print(w, ")"); })
	|	#(CAST_EXPR  { Print(w, "(("); } typeSpec[w]  { Print(w, ")("); }  expr[w]  { Print(w, "))"); } )
	|   newExpression[w]
	|   constant[w]
    |   su:"super"								{ Print(w, #su); }
    |   tr:"true"								{ Print(w, #tr); }
    |   fa:"false"								{ Print(w, #fa); }
    |   th:"this"								{ Print(w, #th); }
    |   nu:NULL									{ Print(w, #nu); }
	|	typeSpec[w] // type name used with instanceof
	   // javaTxt = text to be printed
	   // env = map from env-vars to AST 
	|  javaWrapper[w] 
	;

javaWrapper [TextWriter w] 
  { string javaTxt = ""; } 
	: #( JAVAWRAPPER javaTemplate:IDENTIFIER   { javaTxt = javaTemplate.getText(); }
	           ( {  StringWriter sw = new StringWriter(); 
	                bool saveDoIndent = doIndent;
	                doIndent = false; 
	             } 
	              v:IDENTIFIER (expression[sw] | expr[sw] | elist[sw] ) 
	             {  javaTxt = javaTxt.Replace(#v.getText(), sw.ToString()); 
	                sw.Close(); 
	                doIndent = saveDoIndent; } )* 
	             )      
	     { Print(w, javaTxt); } 
	;
	
ctorCall [TextWriter w]
	:	#( THIS  { Print(w, "this("); }  elist[w]  { Print(w, ")"); })
	|	#( BASE  { Print(w, "super("); } elist[w]  { Print(w, ")"); })
	;

arrayIndex [TextWriter w]
	:	#(ELEMENT_ACCESS_EXPR expr[w]  { Print(w, "["); } elist[w]  { Print(w, "]"); } )
	;

constant [TextWriter w]
    :   it:INT_LITERAL				{ Print(w, #it); }
    |   ch:CHAR_LITERAL				{ Print(w, #ch); }
    |   st:STRING_LITERAL			{ Print(w, #st); }
    |   fl:NUM_FLOAT				{ Print(w, #fl); }
    |   db:DOUBLE_LITERAL			{ Print(w, #db); }
    |   flr:FLOAT_LITERAL			{ Print(w, #flr); }
    |   lo:LONG_LITERAL				{ Print(w, #lo); Print(w, "L"); }
    |   ul:ULONG_LITERAL			{ Print(w, #ul); Print(w, "L"); }
    |   de:DECIMAL_LITERAL			{ Print(w, #de, "/* Unsupported Decimal Literal */"); }
    ;

newExpression [TextWriter w]
	:	#(	ne:OBJ_CREATE_EXPR				{ Print(w, #ne, " "); } 
			typeSpec[w]
			{ Print(w, "("); } elist[w] { Print(w, ")"); } 
			( { PrintNL(w); indentLevel++; Print(w, "{"); PrintNL(w); indentLevel++; }
					objBlock[w]
			  { indentLevel--; Print(w, "}"); indentLevel--; PrintNL(w); }
			)?
		)
	|   #(	na:ARRAY_CREATE_EXPR				{ Print(w, #na, " "); } 
			typeSpec[w] 
			 ( arrayInitializer[w] //rankSpecifiers[w]!
			 | { Print(w, "["); } elist[w] {Print(w, "]"); } 
			   rankSpecifiers[w] ( arrayInitializer[w] )?
			 ) 
		 )
	;

// newArrayDeclarator [TextWriter w]
// 	:	#( ARRAY_DECLARATOR (newArrayDeclarator[w])? { Print(w, "["); }(expression[w])? { Print(w, "]"); })
//	;
