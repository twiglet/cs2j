header {
	using System.IO;
	using System.Collections;
	using Directory = System.IO.Directory;
	using System.Xml.Serialization;
    using Path = System.IO.Path;
}

options {
	language =  "CSharp";
	namespace = "RusticiSoftware.Translator";
}

/** NetTranslator: Converts .Net calls to Java API calls
 *
 * Author: Kevin Glynn <kevin.glynn@scorm.com>
 *
 * This grammar is based on the java tree walker included in ANTLR examples
 *
 */
 
class NetTranslator extends TreeParser("RusticiSoftware.Translator.NetTranslatorBase");

options {
	importVocab = CSharpJava;
	buildAST = true;
	ASTLabelType					= "ASTNode";
	defaultErrorHandler				= true;	
}
{
		// track current namespace
        private string nameSpace = "";
        
        // track current level of switch statement so that we generate unique scrutinee variables
        private int scrutineeCounter = 0;

        // track current level of foreach statement so that we generate unique temp variables
        private int foreachCounter = 0;
        
		// expr.<field>
		// accessAST:#( MEMBER_ACCESS_EXPR thisAST:expr fieldNm:IDENTIFIER )
		private ASTNode ResolveGetter(ASTNode accessAST)
		{
			ASTNode retAST = null;
			ASTNode thisAST = (ASTNode) accessAST.getFirstChild();
			string fieldNm = thisAST.getNextSibling().getText();
			FieldRep fldProp = thisAST.DotNetType.Resolve(fieldNm);
			if (fldProp != null)
			{
				string getter = fldProp.Get;
			    this.addImport(fldProp.Imports); 
				bool thisIsDummyThis = thisAST.Type == THIS && thisAST.getText() == "DUMMYTHIS";
				if (getter == null)
				{   
					string newFieldNm = fieldNm;
					if (fldProp is PropRep)
					    newFieldNm = "get" + newFieldNm + "()";
					
					ASTNode newFieldAST = #( [IDENTIFIER, newFieldNm] );
					
					if (thisIsDummyThis)
					   retAST = newFieldAST;
					else
					   retAST = #( [MEMBER_ACCESS_EXPR], astFactory.dupTree(thisAST), newFieldAST );  
			    }
			    else
			       retAST = (ASTNode) #( [JAVAWRAPPER], [IDENTIFIER, getter], 
							  					           [IDENTIFIER, "${this}"],
												           astFactory.dupTree(thisAST) );
				retAST.DotNetType = fldProp.Type;				
			}
			return retAST;
		}

		// expr.<field> = value
		// accessAST: #( ASSIGN	 targetAST:#( MEMBER_ACCESS_EXPR thisAST:expr fieldNm:IDENTIFIER ) valueAST:expr[w] )
		private ASTNode ResolveSetter(ASTNode assignAST)
		{
			ASTNode retAST = null;
			ASTNode targetAST = (ASTNode) assignAST.getFirstChild();
			ASTNode valueAST = (ASTNode) targetAST.getNextSibling();
			ASTNode thisAST = (ASTNode) targetAST.getFirstChild();
			string fieldNm = thisAST.getNextSibling().getText();
			FieldRep fldProp = thisAST.DotNetType.Resolve(fieldNm);
			if (fldProp != null)
			{
				string setter = fldProp.Set;
			    this.addImport(fldProp.Imports); 				
			    bool thisIsDummyThis = thisAST.Type == THIS && thisAST.getText() == "DUMMYTHIS"; 
				if (thisIsDummyThis)
				   thisAST.setText("this");
				if (setter == null)
				{  
				   // assignment of an application property or field
				   if (fldProp is PropRep)
				      setter = (thisIsDummyThis ? "" : "${this}.") + "set" + fieldNm + "(${value})";
				   else
				      setter = (thisIsDummyThis ? "" : "${this}.") + fieldNm + " = ${value}";
			    }
			    retAST = (ASTNode) #( [JAVAWRAPPER], [IDENTIFIER, setter], 
												        [IDENTIFIER, "${this}"],
												        astFactory.dupTree(thisAST),
												        [IDENTIFIER, "${value}"],
												        astFactory.dupTree(valueAST) );
				retAST.DotNetType = mkType("System.Void");				
			}
			return retAST;
		}

		// new T(<args>)
		// newAST:#( OBJ_CREATE_EXPR #( TYPE type #( ARRAY_RANKS ) ) #( [ELIST] args ) )
		private ASTNode ResolveNewObj(ASTNode newAST)
		{
			ASTNode retAST = null;
			ASTNode typeAST = (ASTNode) newAST.getFirstChild().getFirstChild();
			
			ArrayList argVs = new ArrayList(); 			
			ASTNode argAST = (ASTNode) newAST.getFirstChild().getNextSibling().getFirstChild();
			while  (argAST != null)
			{
				argVs.Add(astFactory.dupTree(argAST));
				argAST = (ASTNode) argAST.getNextSibling();
			}
			
			ClassRep typeClass = typeAST.DotNetType as ClassRep; // If type wasn't found then we will have an InterfaceRep
			
			ConstructorRep constructor = (typeClass == null ? null : typeClass.Resolve(argVs));
						
			if (constructor != null && constructor.Java != null)
			{
				retAST = (ASTNode) #( [JAVAWRAPPER], [IDENTIFIER, constructor.Java]);
			    for (int i = 0; i < argVs.Count; i++)
			    {
					string templateVar = "${" + constructor.Params[i].Name + "}";
					retAST.addChild( #( [IDENTIFIER, templateVar] ) );
					retAST.addChild( (ASTNode) argVs[i] );
			   }
			   this.addImport(constructor.Imports); 				
			   retAST.DotNetType = typeAST.DotNetType;	 
			}

			return retAST;
		}

		// expr.<method>(expr*)
		// invokeAST:#( INVOCATION_EXPR #( MEMBER_ACCESS_EXPR thisAST:expr methodNm:IDENTIFIER) 
		//  							#( [ELIST] args ) )	
		private ASTNode ResolveMethod(ASTNode invokeAST)
		{
			ASTNode retAST = null;
			ASTNode thisAST = (ASTNode) invokeAST.getFirstChild().getFirstChild();
			string methodNm = thisAST.getNextSibling().getText();
			
			ArrayList argVs = new ArrayList(); 			
			ASTNode argAST = (ASTNode) invokeAST.getFirstChild().getNextSibling().getFirstChild();
			while  (argAST != null)
			{
				argVs.Add(astFactory.dupTree(argAST));
				argAST = (ASTNode) argAST.getNextSibling();
			}
			
			MethodRep method = thisAST.DotNetType.Resolve(methodNm, argVs);
						
			if (method != null) {
			   bool thisIsDummyThis = thisAST.Type == THIS && thisAST.getText() == "DUMMYTHIS"; 
			   if (thisIsDummyThis) 
			      thisAST.setText("this");   // if we need 'this' below, then it better not be 'dummythis'  
			   if (method.Java == null)
			   {
			       ASTNode methodAST = (ASTNode) (thisIsDummyThis ? #([IDENTIFIER, methodNm]) : astFactory.dupTree(invokeAST.getFirstChild()));
			       ASTNode argsElistAST = (ASTNode) astFactory.dupTree(invokeAST.getFirstChild().getNextSibling());
			       retAST = #( [INVOCATION_EXPR], methodAST, argsElistAST);
			   }
			   else
			   {  
				  retAST = (ASTNode) #( [JAVAWRAPPER], [IDENTIFIER, method.Java], 
													   [IDENTIFIER, "${this}"],
													   astFactory.dupTree(thisAST));
			      for (int i = 0; i < argVs.Count; i++)
			      {
					   ASTNode arg = (ASTNode) argVs[i];
					   string templateVar = "${" + method.Params[i].Name + "}";
					   retAST.addChild( #( [IDENTIFIER, templateVar] ) );
					   retAST.addChild( astFactory.dupTree(arg) );
					   // Support for extracting type name from typeof() expressions
					   // typeof(<type>) has been transformed to #( [EXPR], #( [JAVAWRAPPER], [IDENTIFIER, "<JavaType>.class"] ) )
					   if (method.Params[i].Name.StartsWith("TYPEOF") &&
					       arg.getFirstChild().Type == JAVAWRAPPER &&
					       arg.getFirstChild().getFirstChild().getText().EndsWith(".class"))
					   {
					        string classCall = arg.getFirstChild().getFirstChild().getText();
					        string typeName = classCall.Substring(0, classCall.Length - 6); // remove trailing ".class"
							retAST.addChild( #( [IDENTIFIER, "${TYPEOF_TYPE}"] ) );
							retAST.addChild( #( [IDENTIFIER, typeName] ) );
							
					   }
			      }
			   }
			   retAST.DotNetType = method.Return;	
			   this.addImport(method.Imports);   
			}
			return retAST;
		}			
		
		// (type) expr
		// castAST:#( CAST_EXPR   tyAST:typeSpec[w]    exprAST:expr[w] )
		private ASTNode ResolveCast(ASTNode castAST)
		{
			ASTNode retAST = null;
			ASTNode tyAST = (ASTNode) castAST.getFirstChild();
			ASTNode exprAST = (ASTNode) castAST.getFirstChild().getNextSibling();
			string template = null;
			
			// We first look for a way to cast expression TO type
			CastRep cast = tyAST.DotNetType.ResolveCastFrom(exprAST.DotNetType);			
			
			if (cast != null)
			{
			   // Initialize template
			   template = cast.Java;
			   if (template == null)
			      template = "${to_type}.__castTo${to_type_id}(${expr})";
			}
			else
			{
			   // If we can't cast TO type, can we cast to type FROM expr' type?
			   cast = exprAST.DotNetType.ResolveCastTo(tyAST.DotNetType);
			   if (cast != null)
			   {
			      // Initialize Template
			      template = cast.Java;
			      if (template == null)
			        template = "${from_type}.__castTo${to_type_id}(${expr})";
			   }
			}   
			if (cast != null)
			{
				// We have found an appropriate castercast.Java;

				retAST = (ASTNode) #( [JAVAWRAPPER], [IDENTIFIER, template], 
													   [IDENTIFIER, "${expr}"],
													      astFactory.dupTree(exprAST),
													   [IDENTIFIER, "${to_type}"],
													      [IDENTIFIER, tyAST.DotNetType.TypeName],
													   [IDENTIFIER, "${from_type}"],
													      [IDENTIFIER, exprAST.DotNetType.TypeName],
													   [IDENTIFIER, "${to_type_id}"],
													      [IDENTIFIER, typeNameToId(tyAST.DotNetType.TypeName)],
													   [IDENTIFIER, "${from_type_id}"],
													      [IDENTIFIER, typeNameToId(exprAST.DotNetType.TypeName)]
									);
			    retAST.DotNetType = tyAST.DotNetType;	
			    this.addImport(cast.Imports);   
			}
			
			return retAST;
		}		
		
		
		// true iff n is being assigned to
		private bool SetterContext(ASTNode n)
		{
			    
			int parentType = n.getParent().Type;			
			
			if (n.getPreviousSibling() != null)
			    return false;
				
			return (parentType == ASSIGN);
		}
				
		// Note, that in Java 6.0 there is getTypeUtils() that could be used to do this conversion
		private Hashtable boxTypeMap = new Hashtable();
		
		// If typeAST is one of the Java unboxed types (char, int, etc.) convert to boxed equivalent (Character, Integer, etc.)
		// updates type name in place!
		private ASTNode boxedType(ASTNode typeAST)
		{
			string type = typeAST.getFirstChild().getText();
			if (boxTypeMap.Contains(type))
			  typeAST.getFirstChild().setText((string)boxTypeMap[type]);
			return typeAST;
		}
		
		private void netTranslatorInit()
		{
		  // Initialize boxTypeMap (see JLS, ed 3 sec 5.1.7)
		  boxTypeMap["boolean"] = "Boolean";
		  boxTypeMap["byte"] = "Byte";
		  boxTypeMap["char"] = "Character";
		  boxTypeMap["short"] = "Short";
		  boxTypeMap["int"] = "Integer";
		  boxTypeMap["long"] = "Long";
		  boxTypeMap["float"] = "Float";
		  boxTypeMap["double"] = "Double";
		  //initialize(netLib);
		  initialize();
		}
		
}



compilationUnit [object w, DirectoryHT env]
  { 
    netTranslatorInit();
    TypeRep.Initialize(env);
	// TypeRep.Test();
    //this.ExtendEnvFromNS("Predefined");
    //this.appEnv = env;
    //TypeRepTemplate.ExtendTranslationCache(env);
    uPath.Push("System");  // C# assumes access to built-in types such as String, Decimal, ...
  }
	:!	#( COMPILATION_UNIT 
			p:packageDefinition[w]   
			u:useDefinitions[w]    
			importDefinitions[w]   
			t:typeDefinition[w] { ## = #( [COMPILATION_UNIT], #p, #u, GetImports(), #t ); }
		)
	;

packageDefinition [object w]
	:	#( PACKAGE_DEF (id:identifier[w]   {
											 // keving:
											 // current namespace should be on top of stack, add it when we do search
											 // uPath.Push(idToString(#id));
											 //ExtendSymTabFromNS(idToString(#id));
											 nameSpace = idToString(#id);
											} )? )				
	;

useDefinitions [object w]
	:	#( USING_DIRECTIVES
			(useDefinition[w])*
		)
	;
	
useDefinition [object w]
	:	#( USING_NAMESPACE_DIRECTIVE	
	       use:identifier[w]	{ string ns = idToString(#use); 
								  if (!ns.StartsWith("System") && !ns.StartsWith("Microsoft"))
								     this.addImport(ns + ".*"); 
								  uPath.Push(ns); 
								  //ExtendSymTabFromNS(ns);
								}	
	       )
	|   #(	USING_ALIAS_DIRECTIVE     	
			alias:identifier[w] 					
			aid:identifier[w] 		{ uPath.Push(idToString(#alias) + "=" + idToString(#aid)); }
		)
	;
	
importDefinitions [object w]
	:	#( IMPORTS 
			(  (importDefinition[w])+ )?
		)   
	;	
	
importDefinition [object w]
	:	#( IMPORT				
	          id:identifier[w]		{ this.addImport(#id.getText()); }    
	       )
	;

typeDefinition [object w]
  {
	 string saveClass = this.ClassInProcess; 
	 TypeRep saveThis = symtab["this"];
	 TypeRep saveSuper =  symtab["super"];
  }
	:!	#(CLASS			
			m:modifiers[w] 
			cn:IDENTIFIER		{ uPath.Push(nameSpace); uPath.Push(nameSpace + "." + #cn.getText());
								  symtab["this"] = mkType(#cn.getText());
								  symtab["super"] = symtab["this"].Extends;
								  this.ClassInProcess = #cn.getText(); }				
			b:classBase[w]		 
			o:objBlock[w]       { uPath.Pop(); uPath.Pop(); }               
			)
			
		{ 
		  ASTNode baseClause = #( [EXTENDS_CLAUSE, "extends"] );
		  ASTNode ifClause = #( [IMPLEMENTS_CLAUSE, "implements"] );
		  
		  ASTNode inherits = (ASTNode) #b.getFirstChild();
		  
		  while ( inherits != null)
		  {
		      if (inherits.DotNetType is ClassRep)
		         baseClause.addChild( astFactory.dupTree(inherits) );
		      else
		         ifClause.addChild( astFactory.dupTree(inherits) );
		      inherits = (ASTNode) inherits.getNextSibling();
		  }
		  
		  ## = #( [CLASS], #m, #cn, baseClause, ifClause, #o);
		  this.ClassInProcess = saveClass;
		  symtab["this"] = saveThis;
		  symtab["super"] = saveSuper;
		}

	|	#(INTERFACE 
			modifiers[w] 
			ifn:IDENTIFIER 		  { uPath.Push(nameSpace); uPath.Push(nameSpace + "." + #ifn.getText()); this.ClassInProcess = #ifn.getText(); }		
			implementsClause[w]		 
			interfaceBlock[w]       
			{ this.ClassInProcess = saveClass; } )	
	|	#(ENUM 
			modifiers[w] 
			en:IDENTIFIER 		  { uPath.Push(nameSpace); uPath.Push(nameSpace + "." + #en.getText()); this.ClassInProcess = #en.getText(); }	
			implementsClause[w]		 
			enumBlock[w]			
			{ this.ClassInProcess = saveClass; } )
	|	#(ANNOTATION 
			modifiers[w] 
			ann:IDENTIFIER 		  { uPath.Push(nameSpace); uPath.Push(nameSpace + "." + #ann.getText()); this.ClassInProcess = #ann.getText(); }	 
			anno:objBlock[w]       
			{ this.ClassInProcess = saveClass; } )	
	;

classBase [Object w]
	:
	   #( CLASS_BASE ( type[w] )* )
	;

typeSpec! [object w]
	:	#(TYPE 
			t:type[w]		
			rs:rankSpecifiers[w]
			{  
			    string typeName = #t.DotNetType.TypeName;
				## = #( [TYPE], #t, #rs );
				int numRanks = #rs.getNumberOfChildren();
				for (int i = 0; i < numRanks; i++)
				   typeName += "[]";
				##.DotNetType = mkType(typeName);
			}			
		) 
	;
	
	// Int[,][] arr;
rankSpecifiers [object w]
	:	#(	ARRAY_RANKS (rankSpecifier[w])* )  
	;
	
rankSpecifier  [object w]
	:	#(ARRAY_RANK	
			( COMMA  // Notice, we ignore dimensions.
			)* 			
		) 
	;
	
typeSpecArray [object w]
	:	#( ARRAY_DECLARATOR 
			typeSpecArray[w]				
			)
	|	type[w]
	;

type! [object w]
  { TypeRep tyRep = null; }
	:  id:identifier[w]     { tyRep = mkType(idToString(#id)); 
							  this.addImport(tyRep.Imports);
							  if (tyRep.Java != null)
								## = #([IDENTIFIER, tyRep.Java]);
							  else
								## = #id;
							  ##.DotNetType = tyRep;
							}
	|  bt:builtInType[w]    { tyRep = #bt.DotNetType; 
							  this.addImport(tyRep.Imports);
							  if (tyRep.Java != null)
								## = #([IDENTIFIER, tyRep.Java]);
							  else
								## = #bt;
							  ##.DotNetType = tyRep;
							}
	|  #(JAVAWRAPPER jid:identifier[w]) { ## = #jid; ##.DotNetType = mkType("A JAVA TYPE"); } 
	;

builtInType [object w]
    :   VOID		{ ##.DotNetType = mkType("System.Void"); }		
    |   OBJECT		{ ##.DotNetType = mkType("System.Object"); }		
    |   BOOL		{ ##.DotNetType = mkType("System.Boolean"); }		
    |   STRING		{ ##.DotNetType = mkType("System.String"); }		
    |   SBYTE		{ ##.DotNetType = mkType("System.SByte"); }		
    |   "char"		{ ##.DotNetType = mkType("System.Char"); }		
    |   "short"		{ ##.DotNetType = mkType("System.Int16"); }		
    |   "int"		{ ##.DotNetType = mkType("System.Int32"); }		
    |   "float"		{ ##.DotNetType = mkType("System.Single"); }		
    |   "double"	{ ##.DotNetType = mkType("System.Double"); }		
    |   "long"		{ ##.DotNetType = mkType("System.Int64"); }		
    |   UBYTE		{ ##.DotNetType = mkType("System.Byte"); }		
    |   DECIMAL		{ ##.DotNetType = mkType("System.Decimal"); }	
    |   UINT		{ ##.DotNetType = mkType("System.UInt32"); }		
    |   ULONG		{ ##.DotNetType = mkType("System.UInt64"); }	
    |   USHORT		{ ##.DotNetType = mkType("System.UInt16"); }
    |   BYTE		{ ##.DotNetType = mkType("System.Byte"); }		// What to do?		
    ;

modifiers [object w]
	:	#( MODIFIERS (modifier[w]      
			)* )
	;

modifier [object w]
    :   "private"				
    |   "public"				
    |   "protected"				
    |   "static"				
    |   "transient"				
    |   FINAL					   
    |   ABSTRACT				
    |   "native"				
    |   "threadsafe"			
    |   "synchronized"			
    |   "const"					
    |   "volatile"				
	|	"strictfp"				
    ;

extendsClause [object w]
    //OK, OK, really we can only extend 1 class, but the tree stores a list so ....
	:	#(EXTENDS_CLAUSE 
			( type[w] )* 
		 )
	;

implementsClause [object w]
 	:	#(IMPLEMENTS_CLAUSE 
 			( type[w] )* 
 		 )
	;


interfaceBlock [object w]
	:	#(	MEMBER_LIST
			(	methodDecl[w] 
			|	variableDef[w, false] 
			|	typeDefinition[w] 
			)*
		)
	;
	
objBlock [object w]
	:	#(	MEMBER_LIST
			(	 ctorDef[w] 
			|	 methodDef[w] 
			|	 variableDef[w, true] 
			|	 typeDefinition[w] 
			|    operatorDef[w]
			|	 #(STATIC_CTOR_DECL  
						slist[w] )
			|	 #(INSTANCE_INIT 
					slist[w] ) 
			)*
		) 
	;

enumBlock [object w]
	:	#(	MEMBER_LIST
			(	#( IDENTIFIER  ( expression[w])?) 
			)*
		)
	;
	
ctorDef [object w]
	:	#(CTOR_DECL 
			modifiers[w]	
			methodHead[w]	 
			(slist[w])?)	
	;

methodDecl [object w]
	:	#(METHOD_DECL 
			modifiers[w] 
			typeSpec[w]						  
			methodHead[w])
	;

methodDef [object w]
	:	#(METHOD_DECL						
			modifiers[w] 
			typeSpec[w]	        { symtab.PushLevel(); }					
			methodHead[w]					
			(slist[w])?						 
			)					{ symtab.PopLevel(); }
	;

variableDef [object w, bool isCreate]
	:	#(FIELD_DECL
			modifiers[w] 
			t:typeSpec[w]					
			(variableDeclarator[w, #t, isCreate])+
			//varInitializer[w]
		) 
	;

operatorDef [object w]
  { ASTNode retAST = null;
  }
	:	(	#(	UNARY_OP_DECL modifiers[w]
				typeSpec[w] overloadableUnaryOperator[w]
				paramList[w]  
	 			slist[w]
		 	)
		|	#(	BINARY_OP_DECL modifiers[w]
				typeSpec[w] overloadableBinaryOperator[w]
				paramList[w] 
		 		slist[w]
			 )
		|!   // A Type conversion operator.  We translate this to a method "__cast[To/From]<type>()" method	
			 // We treat both types as EXPLICIT because (at least for now) we need the explicit cast to tell
			 // us to resolve the conversion
		   #(	CONV_OP_DECL m:modifiers[w]  { retAST = #( [METHOD_DECL], astFactory.dupTree(#m) ); }
				( IMPLICIT | EXPLICIT ) it:typeSpec[w]	   
					ips:paramList[w] ib:slist[w]
										   { string convertTo = #it.DotNetType.TypeName;
										     string convertFrom = ((ASTNode) #ips.getFirstChild().getFirstChild()).DotNetType.TypeName;
										     string currentClass = (nameSpace != ""? nameSpace + ".":"") + ClassInProcess;
										     bool isTo = convertTo == currentClass;
										     if (!isTo && convertFrom != currentClass)
										     {   
										        Console.Error.Write("ERROR -- (Converting Cast Operator " + convertFrom + " to " + convertTo + ") ");
										        Console.Error.WriteLine("should match enclosing class " +  currentClass);
										     }
										     string methodNm = "__castTo" + typeNameToId(convertTo); 
											 retAST.addChild( astFactory.dupTree(#it) ); 
											 retAST.addChild( #([IDENTIFIER, methodNm]) ); 
											 retAST.addChild( astFactory.dupTree(#ips) );
											 retAST.addChild( #( [THROWS, "throws"], [IDENTIFIER, "Exception"] ) );
											 retAST.addChild( astFactory.dupTree(#ib) );
										   }
			)  { ## = retAST; }
		)
	;

overloadableUnaryOperator [object w]
	:  UNARY_PLUS	
	|  UNARY_MINUS	
	|  LOG_NOT		
	|  BIN_NOT		
	|  INC			
	|  DEC			
	|  TRUE			
	|  FALSE		
	;
	
overloadableBinaryOperator [object w]
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

parameterDef [object w]
	:	#(PARAMETER_FIXED  
			t:typeSpec[w]					
			id:IDENTIFIER          { symtab[#id.getText()] = #t.DotNetType; }					
			)
	|   #(PARAMS tp:typeSpec[w] 
	             idp:IDENTIFIER    
	             { // idp is actually an array of tp
	               symtab[#idp.getText()] = mkType(#tp.DotNetType.TypeName + "[]")
	               ; } 
	             )
	;

objectinitializer [object w]
	:	#(INSTANCE_INIT slist[w]  )
	;

variableDeclarator [object w, ASTNode t, bool isCreate]
  { bool initted = false; }
	:	#( VAR_DECLARATOR 
				id:IDENTIFIER	            
				(varInitializer[w] { initted = true; } )?  
				   { symtab[#id.getText()] = t.DotNetType;  // keving: I assume id is not valid in initializer
				     if (isCreate && !initted)
				     {
				        if ( t.DotNetType is StructRep )
							##.addChild( #( [VAR_INIT], #( [EXPR], #( [OBJ_CREATE_EXPR, "new"],
																	 astFactory.dupTree(t),
																	#( [EXPR_LIST] ) ) ) ) );
						if ( t.DotNetType is EnumRep )
						{
						    string enumZero = ((EnumRep) t.DotNetType).getField(0);
						    ##.addChild( #( [VAR_INIT], #( [EXPR], #( [MEMBER_ACCESS_EXPR, "."],
																	 astFactory.dupTree(t.getFirstChild()),
																	#( [IDENTIFIER, enumZero] ) ) ) ) );
						}
				     }
				   }
		)
//	|	LBRACK variableDeclarator[w]	
	;

varInitializer [object w]
	:	#(VAR_INIT				      
			initializer[w])   
	;

initializer [object w]
	:	expression[w]
	|	arrayInitializer[w]
	;

arrayInitializer [object w]
	:	#(ARRAY_INIT (initializer[w])* )
	;

methodHead [object w]
 	:	IDENTIFIER paramList[w] (throwsClause[w])?
	;

paramList [object w]
 	:   #( FORMAL_PARAMETER_LIST
				( parameterDef[w] )* 
		  )
	;

throwsClause [object w]
 	:	#( "throws"						 
			( identifier[w] (  identifier[w] )* )?
		)
	;

identifier [object w]
	:   IDENTIFIER						
	|	#( DOT IDENTIFIER  identifier[w]  )      
	;

identifierStar [object w]
	:	IDENTIFIER										
	|   STAR												  
	|	#( DOT IDENTIFIER  identifier[w]  ) 
	;

slist [object w]
	:	#( BLOCK  { symtab.PushLevel(); }	(stat[w])*  { symtab.PopLevel(); }	 )
	|   EMPTY_STMT 
	;

// Like a slist[].  Appears in switch alternatives
statementList [object w]
	:	#( STMT_LIST (stat[w])* )
	;

stat [object w]
    : typeDefinition[w]
	|	variableDef[w, true]							
	|	#(EXPR_STMT expression[w])				
	|	#(LABEL_STMT IDENTIFIER	 stat[w])
	|	#(IF								
			expression[w]						
			stat[w]								
			( #(ELSE									 
				  stat[w])								
				)? 
			)
	|	#(	"for"									
			#(FOR_INIT (variableDef[w, true])* (expression[w] (  expression[w])* )?) 
			#(FOR_COND (expression[w])?)			
			#(FOR_ITER (expression[w] (  expression[w])* )?)					
			stat[w]										
		)
	|!	{ foreachCounter++; }
	    #("foreach"									
			def:variableDef[w, true]								
			ce:expression[w]								
			bod:stat[w]										
		  )		
			{
			    foreachCounter--;
			    string tempVar = "__o" + (foreachCounter > 0 ? foreachCounter+"" : "");
			    ASTNode retAST;
			    ASTNode typeAST = (ASTNode) #def.getFirstChild().getNextSibling();
				string typeOfVar = typeToString(typeAST, false);
			    ASTNode initVar = (ASTNode) #def.getFirstChild().getNextSibling().getNextSibling().getFirstChild();
			    // If target expression supports interface IDictionary then we will be getting back DictionaryEntry's, for Java 
			    // assume the expression #CE implements interface Map and call entrySet()
			    ASTNode iterableAST;
			    if (mkType("System.Collections.IDictionary").IsA(#ce))
			    {
			       iterableAST = #( [EXPR], #( [JAVAWRAPPER], [IDENTIFIER, "${ce}.entrySet()"], 
																			   [IDENTIFIER, "${ce}"], astFactory.dupTree(#ce) ) );
			    } else
			    if (mkType("System.String").IsA(#ce))
			    {
			       iterableAST = #( [EXPR], #( [JAVAWRAPPER], [IDENTIFIER, "${ce}.toCharArray()"], 
																			   [IDENTIFIER, "${ce}"], astFactory.dupTree(#ce) ) );
			    } else
			    {
			       iterableAST = (ASTNode) astFactory.dupTree(#ce);
			    }
			    retAST = #( [FOREACH, "foreach"],
			               #( [FIELD_DECL], #([MODIFIERS]),
			                                #( [TYPE], #([IDENTIFIER, "Object"]), #([ARRAY_RANKS]) ),
											#( [VAR_DECLARATOR], #( [IDENTIFIER, tempVar] ) ) ),
			               iterableAST);
			    retAST.addChild( #( [BLOCK],
								#( [FIELD_DECL], astFactory.dupTree(#def.getFirstChild()),
			                                     astFactory.dupTree(typeAST),
											     #( [VAR_DECLARATOR], 
											           astFactory.dupTree(initVar),
											           #( [VAR_INIT],
											                #( [EXPR], #( [CAST_EXPR], astFactory.dupTree(boxedType(typeAST)), #( [IDENTIFIER, tempVar] ) ) ) ) ) ), 
			                    #bod ) );
			    
			    ## = retAST;
			  }
	|	#("while"									
			expression[w]								
			stat[w]										
			)
	|	#("do"										 
			stat[w]										
			expression[w]								
			)
	|	#("goto"	 IDENTIFIER			 )
	|	#("break"	 (  IDENTIFIER)?			 )
	|	#("continue"  (  IDENTIFIER)?			 )
	|	#("return"	 (  expression[w])?  )
	|! { ASTNode scrutinee = null;
	     ASTNode retAST = null; 
	     ASTNode iteAST = null;
	   }	
	   #("switch"			
			se:expression[w] { if (isValidScrutinee(#se))
							   {
							       retAST = #( [SWITCH, "switch"], #se ); 
							   }
							   else
							   {
							       // Declare a variable with the right type to hold the scrutinee 
							       string scrutType;
							       string scrutVar;
							       if (#se.DotNetType.Java != null)
									  scrutType = #se.DotNetType.Java;
								   else
								      scrutType = #se.DotNetType.TypeName;
								   scrutVar = "__scrut" + scrutineeCounter;
								   scrutineeCounter++;
								   // Add to symtab
								   symtab[scrutVar] = #se.DotNetType;
								   scrutinee = #( [IDENTIFIER, scrutVar] );
							       retAST = #( [BLOCK], #( [FIELD_DECL], [MODIFIERS], #( [TYPE], [IDENTIFIER, scrutType], [ARRAY_RANKS] ),
																			   #( [VAR_DECLARATOR], scrutinee, #( [VAR_INIT], 
																												  astFactory.dupTree(#se) ) ) ) );
							   };	 
							 }		
			(cg:caseGroup[w, scrutinee] { if (scrutinee == null)
							   {
							      retAST.addChild(#cg);
							   }
							   else
							   {
							     // cg is if (...) { ...  }
							      if (iteAST == null)
							         retAST.addChild(#cg);
							      else
							         iteAST.addChild( #( [ELSE, "else"], ( [BLOCK],  #cg ) ) );
							      iteAST = #cg;
							   };
							  
							  } )*		
			{ if (scrutinee != null)
			     scrutineeCounter--;
			  ## = retAST; 
			}				  
			)					
	|	#("throw"		 expression[w]  )
	|	#("synchronized"			 
				expression[w]		
				stat[w]				
				)
	|	tryBlock[w]
	|	slist[w] 
    // uncomment to make assert JDK 1.4 stuff work
    // |   #("assert" expression[w] (expression[w])?)
	|	ctorCall[w]									
	;

// If s is null then this is a real case, else we are transforming it to if-then-else statements
caseGroup! [Object w, ASTNode s]
  { ASTNode retAST = null;
    ASTNode condAST = null; 
  } 
	:	#(SWITCH_SECTION 
	                      ( #("case" e1:expression[w] { if (s == null) 
														{	ASTNode constAST = null;
															if (mkType("System.Enum").IsA(#e1.DotNetType))
															{
															   // Enums must not be qualified
															   ASTNode strippedConst = stripQualifier((ASTNode)#e1.getFirstChild());
															   constAST = #( [EXPR], strippedConst);
															}
															else
														       constAST = (ASTNode) astFactory.dupTree(#e1);
															retAST = #( [SWITCH_SECTION], 
															              #( [CASE, "case"], constAST ) );
														}
													    else
													        condAST = #( [JAVAWRAPPER], [IDENTIFIER, "${this}.equals(${arg})"], 
																			[IDENTIFIER, "${this}"], astFactory.dupTree(s),
																			[IDENTIFIER, "${arg}"], astFactory.dupTree(#e1.getFirstChild()) ); }
						      )  
						      | "default" {  if (s == null) 
											  retAST = #( [SWITCH_SECTION], #( [DEFAULT, "default"] ) );
											else
											  condAST = #( [TRUE, "true"] );
										  }
					      )  
	                      ( #("case" en:expression[w] { if (s == null) 
														{
															ASTNode constAST = null;
															if (mkType("System.Enum").IsA(#en.DotNetType))
															{
															   // Enums must not be qualified
															   ASTNode strippedConst = stripQualifier((ASTNode)#en.getFirstChild());
															   constAST = #( [EXPR], strippedConst);
															}
															else
														       constAST = (ASTNode) astFactory.dupTree(#en);
															retAST.addChild( #( [CASE, "case"], constAST ) );
														}
													    else
													    {
													       if ( condAST == null || condAST.Type != TRUE ) 
													         condAST = #( [LOG_OR, "||"], condAST, #( [JAVAWRAPPER], [IDENTIFIER, "${this}.equals(${arg})"], 
																			[IDENTIFIER, "${this}"], astFactory.dupTree(s),
																			[IDENTIFIER, "${arg}"], astFactory.dupTree(#en.getFirstChild()) ) ); }
														}															
	                          ) 
	                          | "default" {  if (s == null) 
											  retAST.addChild( #( [DEFAULT, "default"] ) );
											 else
											   condAST = #( [TRUE, "true"] );  // We must always take this option, ignore previous
										  }
						   )*
					  sl:statementList[w]
					  { if (s == null)
					      retAST.addChild( astFactory.dupTree(#sl) );
					    else
					    {  // strip trailing break from sl
					       ASTNode slAST = (ASTNode) #sl.getFirstChild();
					       if (slAST != null)
					       {
							  ASTNode prevAST = null;
							  ASTNode nextAST = slAST;
						      while (nextAST.getNextSibling() != null)
					          {
					             prevAST = nextAST;
					             nextAST = (ASTNode) nextAST.getNextSibling();
					          }
					          if (nextAST.Type == BREAK)
					          {
					             // Strip break
					             if (prevAST == null)
					                slAST = null;
					             else
					                prevAST.setNextSibling(null);
					          }
					       }
					       if (condAST == null || condAST.Type == TRUE)
					          retAST = slAST;
					       else
					          retAST = #( [IF, "if"],  #( [EXPR], condAST), #( [BLOCK], slAST ) );
					    }
					    ## = retAST;
					  }  
	      )		
	;

tryBlock [object w]
	:	#( "try"				
			slist[w]			 
			(handler[w])* 
			(#("finally"     
				slist[w]		
				))? 
			)
	;

handler [object w]
	:	#( "catch"				
			( // typeSpec[w] | 
			  variableDef[w, false] )			
			slist[w]				
			)
	;

elist [object w]
	:	#( EXPR_LIST
			( expression[w] )*
		)
	;

expression [object w]
	:	#(EXPR e:expr[w])   { ##.DotNetType = #e.DotNetType; }  
	;

expr [object w]
		// Set expression type to be the type of the 'then' part (but maybe it should be the least of 'then' and 'else'??)
	:	#( QUESTION expr[w] t1:expr[w] expr[w] )	{ ##.DotNetType = #t1.DotNetType; }
        // binary operators...

	|   assignOp[w] 
    |   #( BIN_OR op1:expr[w] expr[w] )				{ ##.DotNetType = #op1.DotNetType; }
    |   #( BIN_XOR op2:expr[w] expr[w] )			{ ##.DotNetType = #op2.DotNetType; }
    |   #( BIN_AND op3:expr[w] expr[w] )			{ ##.DotNetType = #op3.DotNetType; }
    |   #( SHIFTL op4:expr[w] expr[w] )				{ ##.DotNetType = #op4.DotNetType; }
    |   #( SHIFTR op5:expr[w] expr[w] )				{ ##.DotNetType = #op5.DotNetType; }
    |   #( BSR op6:expr[w] expr[w] )				{ ##.DotNetType = #op6.DotNetType; }
    |   #( PLUS op7:expr[w] expr[w] )				{ ##.DotNetType = #op7.DotNetType; }
    |   #( MINUS op8:expr[w] expr[w] )				{ ##.DotNetType = #op8.DotNetType; }
    |   #( DIV op9:expr[w] expr[w] )				{ ##.DotNetType = #op9.DotNetType; }
    |   #( MOD op10:expr[w] expr[w] )				{ ##.DotNetType = #op10.DotNetType; }
    |   #( STAR op11:expr[w] expr[w] )				{ ##.DotNetType = #op11.DotNetType; }


	|  #( INSTANCEOF expr[w] typeSpec[w] )			{ ##.DotNetType = mkType("System.Boolean"); }
	// In C# strings are always compared by content
	|!  #( ope:EQUAL eq1:expr[w] eq2:expr[w] )					
	     { ASTNode retAST = null;
	       if (#eq1.DotNetType.TypeName == "System.String" ||
	            #eq2.DotNetType.TypeName == "System.String" )
	       {
	            retAST = #( [JAVAWRAPPER], [IDENTIFIER, "StringSupport.equals(${s1},${s2})"], 
	                          [IDENTIFIER, "${s1}"], astFactory.dupTree(#eq1),
	                          [IDENTIFIER, "${s2}"], astFactory.dupTree(#eq2) );
	            this.addImport("RusticiSoftware.System.StringSupport");
	       }   
	       else
	       if (#eq1.DotNetType.TypeName == "System.DateTime" ||
	            #eq2.DotNetType.TypeName == "System.DateTime" )
	       {
	            retAST = #( [JAVAWRAPPER], [IDENTIFIER, "(${d1} == ${d2} || ${d1}.getTime() == ${d2}.getTime())"], 
	                          [IDENTIFIER, "${d1}"], astFactory.dupTree(#eq1),
	                          [IDENTIFIER, "${d2}"], astFactory.dupTree(#eq2) );
	       }   
	       else
	           retAST = #( #ope, #eq1,  #eq2);
	       retAST.DotNetType = mkType("System.Boolean");
	       ## = retAST; 
	     }
	|!  #( opn:NOT_EQUAL ne1:expr[w] ne2:expr[w] )
	     { ASTNode retAST = null;
	       if (#ne1.DotNetType.TypeName == "System.String" ||
	            #ne2.DotNetType.TypeName == "System.String")
	       {
	            retAST = #( [LOG_NOT, "!"],
	                        #( [JAVAWRAPPER], [IDENTIFIER, "StringSupport.equals(${s1}, ${s2})"], 
	                              [IDENTIFIER, "${s1}"], astFactory.dupTree(#ne1),
	                              [IDENTIFIER, "${s2}"], astFactory.dupTree(#ne2) ) );
	            this.addImport("RusticiSoftware.System.StringSupport");
	       }
	       else
	       if (#ne1.DotNetType.TypeName == "System.DateTime" ||
	            #ne2.DotNetType.TypeName == "System.DateTime" )
	       {
	            retAST = #( [JAVAWRAPPER], [IDENTIFIER, "(${d1} != ${d2} && ${d1}.getTime() != ${d2}.getTime())"], 
	                              [IDENTIFIER, "${d1}"], astFactory.dupTree(#ne1),
	                              [IDENTIFIER, "${d2}"], astFactory.dupTree(#ne2) );
	       }   
	       else
	           retAST = #( #opn, #ne1, #ne2);
	       retAST.DotNetType = mkType("System.Boolean");
	       ## = retAST; 
	     }
	|!  #( opl:LTHAN lt1:expr[w] lt2:expr[w] )	
		 { ASTNode retAST = null;
	       if (#lt1.DotNetType.TypeName == "System.DateTime" || #lt2.DotNetType.TypeName == "System.DateTime")
	           retAST = #( [JAVAWRAPPER], [IDENTIFIER, "${this}.before(${arg})"], 
	                          [IDENTIFIER, "${this}"], astFactory.dupTree(#lt1),
	                          [IDENTIFIER, "${arg}"], astFactory.dupTree(#lt2) );
	       else
	           retAST = #( #opl, #lt1,  #lt2);
	       retAST.DotNetType = mkType("System.Boolean");
	       ## = retAST; 
	     }
	|!  #( opg:GTHAN gt1:expr[w] gt2:expr[w] )
		 { ASTNode retAST = null;
	       if (#gt1.DotNetType.TypeName == "System.DateTime" || #gt2.DotNetType.TypeName == "System.DateTime")
	           retAST = #( [JAVAWRAPPER], [IDENTIFIER, "${this}.after(${arg})"], 
	                          [IDENTIFIER, "${this}"], astFactory.dupTree(#gt1),
	                          [IDENTIFIER, "${arg}"], astFactory.dupTree(#gt2) );
	       else
	           retAST = #( #opg, #gt1,  #gt2);
	       retAST.DotNetType = mkType("System.Boolean");
	       ## = retAST; 
	     }
	|!  #( opge:GTE ge1:expr[w] ge2:expr[w] )
		 { ASTNode retAST = null;
	       if (#ge1.DotNetType.TypeName == "System.DateTime" || #ge2.DotNetType.TypeName == "System.DateTime")
	           retAST = #( [JAVAWRAPPER], [IDENTIFIER, "(${this}.compareTo(${arg}) >= 0)"], 
	                          [IDENTIFIER, "${this}"], astFactory.dupTree(#ge1),
	                          [IDENTIFIER, "${arg}"], astFactory.dupTree(#ge2) );
	       else
	           retAST = #( #opge, #ge1,  #ge2);
	       retAST.DotNetType = mkType("System.Boolean");
	       ## = retAST; 
	     }
	|!  #( ople:LTE le1:expr[w] le2:expr[w] )
		 { ASTNode retAST = null;
	       if (#le1.DotNetType.TypeName == "System.DateTime" || #le2.DotNetType.TypeName == "System.DateTime")
	           retAST = #( [JAVAWRAPPER], [IDENTIFIER, "(${this}.compareTo(${arg}) <= 0)"], 
	                          [IDENTIFIER, "${this}"], astFactory.dupTree(#le1),
	                          [IDENTIFIER, "${arg}"], astFactory.dupTree(#le2) );
	       else
	           retAST = #( #ople, #le1,  #le2);
	       retAST.DotNetType = mkType("System.Boolean");
	       ## = retAST; 
	     }
	|  #( LOG_OR expr[w] expr[w] )					{ ##.DotNetType = mkType("System.Boolean"); }
	|  #( LOG_AND expr[w] expr[w] )					{ ##.DotNetType = mkType("System.Boolean"); }


	|  #( INC op12:expr[w] )						{ ##.DotNetType = #op12.DotNetType; }
	|  #( DEC op13:expr[w] )						{ ##.DotNetType = #op13.DotNetType; }
	|  #( POST_INC_EXPR op14:expr[w] )				{ ##.DotNetType = #op14.DotNetType; }
	|  #( POST_DEC_EXPR op15:expr[w] )				{ ##.DotNetType = #op15.DotNetType; }
	|  #( UNARY_MINUS op16:expr[w] )				{ ##.DotNetType = #op16.DotNetType; }
	|  #( UNARY_PLUS op17:expr[w] )					{ ##.DotNetType = #op17.DotNetType; }
	|  #( BIN_NOT op18:expr[w] )					{ ##.DotNetType = #op18.DotNetType; }
	|  #( LOG_NOT op19:expr[w] )					{ ##.DotNetType = #op19.DotNetType; }

    |	primaryExpression[w]
	;
	
assignOp! [Object w]

	: #( op:ASSIGN	left:expr[w] right:expr[w] )
		{ 
		    ASTNode kosherInp = #( astFactory.dupTree(#op), astFactory.dupTree(#left), astFactory.dupTree(#right) );
		    ASTNode retAST = null;
			if ( #left.Type == MEMBER_ACCESS_EXPR  && 
			     #left.getFirstChild().getNextSibling().Type == IDENTIFIER)
			{
				retAST = ResolveSetter( kosherInp );
				if (retAST == null)
				   retAST = kosherInp;
			}
			else if ( #left.Type == ELEMENT_ACCESS_EXPR )
			{
			   TypeRep at = ((ASTNode)#left.getFirstChild()).DotNetType;
			   if (at.TypeName.EndsWith("[]") || at.TypeName == "System.Array")
			   {
			     // A real array :-)
			     retAST = kosherInp;
			   }
			   else
			   {
			      ASTNode objAST = (ASTNode) astFactory.dupTree(#left.getFirstChild());
			      ASTNode keyAST = (ASTNode) astFactory.dupTree(#left.getFirstChild().getNextSibling().getFirstChild());
			      retAST = ResolveMethod( #( [INVOCATION_EXPR], #( [MEMBER_ACCESS_EXPR], objAST, 
			                                                                             [IDENTIFIER, "set___idx"]), 
			                                                    #( [EXPR_LIST], keyAST, 
			                                                                astFactory.dupTree(#right))) ); 
			      if (retAST == null)
			      {
				      retAST = kosherInp;
			      }
			   }
			}
			else if (#left.Type == IDENTIFIER)
			{
			   // Try to resolve to a local variable / property
			   ASTNode thisNode = #( [THIS, "DUMMYTHIS"] );
			   thisNode.DotNetType = symtab["this"];
			   retAST = ResolveSetter( #( astFactory.dupTree(#op), #( [MEMBER_ACCESS_EXPR], thisNode, astFactory.dupTree(#left) ), 
																      astFactory.dupTree(#right) ) );
			}
			if (retAST == null)
			{
			   retAST = kosherInp;
			}
			## = retAST;
			##.DotNetType = mkType("System.Void"); 
		}
	;
	
primaryExpression [object w]
    :   v:IDENTIFIER					{ 
										    ASTNode retAST = null;
										    TypeRep retType = null;
										    
										    // Look for identifier in symbol table
										    retType = symtab[#v.getText()];
										    if (retType != null)
										    {
										       retAST = #v;
										       retAST.DotNetType = retType;
										    }
										    else   
										    {
										       if ( ##_in.getParent().Type != INVOCATION_EXPR && 
					                                 !SetterContext(##_in) )
											   {   // Looking for a property or field
												   ASTNode thisNode = #( [THIS, "DUMMYTHIS"] );
												   thisNode.DotNetType = symtab["this"];
											       retAST = ResolveGetter( #( [MEMBER_ACCESS_EXPR], thisNode, #v) );
											   }
											   
											   if (retAST == null)
											   {
												  if ( ##_in.getParent().Type == INVOCATION_EXPR)
												  {
												     // method call
												     retAST = #v;
												     retAST.DotNetType = null;
												  }
												  else
												  {
											        // Might be part of a reference to a static member of a type
											        retType = mkType(#v.getText());
											      
											        if (retType != null)
											        {
											           retAST = #v;
											           retAST.DotNetType = retType;
											        }
											        else
											        { 
													  // TODO: Probably part of a qualified type name
													  retAST = #v;
													  retAST.DotNetType = mkType("UNKNOWN TYPE");
												    }
												  }
											    }
										     }
										    ## = retAST;
										}							
    |   #( JAVAWRAPPER identifier[w] (identifier[w] (expression[w]|expr[w]|elist[w]))* ) 
                    { 
                           if (##.DotNetType == null) {
                                  ##.DotNetType = mkType("System.Object"); 
                           }
                           else {
                                  // We saved just the type name on the previous pass
                                  ##.DotNetType = mkType(##.DotNetType.TypeName);
                           }
                    }
    |   memberAccessExpr[w]
	|	arrayIndex[w]
	|!	#(INVOCATION_EXPR e:primaryExpression[w]   args:elist[w] )
					{
					    ASTNode kosherInp = #( [INVOCATION_EXPR], #e, #args);
					    ASTNode retAST = null;
					    if (#e.Type == IDENTIFIER && symtab[#e.getText()] == null)
					    {
					      // Is it a local method call?
						  ASTNode thisNode = #( [THIS, "DUMMYTHIS"] );
						  thisNode.DotNetType = symtab["this"];
						  retAST = ResolveMethod( #( [INVOCATION_EXPR], #( [MEMBER_ACCESS_EXPR], thisNode, astFactory.dupTree(#e)),
						                                                 astFactory.dupTree(#args)) );
					    }
						else if (#e.Type == MEMBER_ACCESS_EXPR && #e.getFirstChild().getNextSibling().Type == IDENTIFIER)
						{  // resolve method call
							retAST = ResolveMethod( kosherInp );
						}
						if (retAST == null) {
						   retAST = kosherInp;
						   retAST.DotNetType = mkType("System.Object");
						}
						
						## = retAST;
						
					}
	|!	#( CAST_EXPR   t:typeSpec[w]    ce:expr[w] )					
	         { 
	             ASTNode kosherInp = #( [CAST_EXPR], #t, #ce );
	             ASTNode retAST = null;
	             	             
	             retAST = ResolveCast( kosherInp );
	             if (retAST == null)
	             {
	                retAST = kosherInp;
	             }
	             
	             ## = retAST;
	             ##.DotNetType = #t.DotNetType; 
	         }
	|   newExpression[w]
	|   constant[w]
    |   "super"														{ ##.DotNetType = symtab["super"]; }
    |   "true"														{ ##.DotNetType = mkType("System.Boolean"); }					
    |   "false"														{ ##.DotNetType = mkType("System.Boolean"); }					
    |   "this"														{ ##.DotNetType = symtab["this"]; }
    |   NULL														{ ##.DotNetType = mkType("System.Object"); }
	|	typeSpec[w] // type name used with instanceof
	;

memberAccessExpr [object w]
 { ASTNode ret = null; }
    :!   #(	MEMBER_ACCESS_EXPR					
				(	te:expr[w]				   	 
					(	m:IDENTIFIER		{ 
											    ASTNode kosherInp = #( [MEMBER_ACCESS_EXPR], #te, #m);
											    ASTNode retAST = null;
											    if ( ##_in.getParent().Type != INVOCATION_EXPR && 
					                               !SetterContext(##_in) )
											    {   // Looking for a property or field
											        retAST = ResolveGetter( kosherInp );
											    }
											    if ( retAST == null )
											    {
											    	retAST = kosherInp;
											    	retAST.DotNetType = mkType("System.Object");
											    }
											    ## = retAST;
											}		
					|	ai:arrayIndex[w]	{  ## = #( [MEMBER_ACCESS_EXPR], #te, #ai); }
					|	th:"this"			{  ## = #( [MEMBER_ACCESS_EXPR], #te, #th); }		
					|	cl:"class"			{  ## = #( [MEMBER_ACCESS_EXPR], #te, #cl); }		
					|	#( n:"new" i:IDENTIFIER  es:elist[w]  )   {  ## = #( [MEMBER_ACCESS_EXPR], #te, #( #n, #i, #es ) ); }
					|   sp:"super"			{  ## = #( [MEMBER_ACCESS_EXPR], #te, #sp); }
					)
				|	 #(ARRAY_DECLARATOR t:typeSpecArray[w]   )    {  ## = #( [MEMBER_ACCESS_EXPR], #([ARRAY_DECLARATOR], #t) ); }
				|	 bt:builtInType[w] { ## = #( [MEMBER_ACCESS_EXPR], #bt); } (cl1:"class" { ##.addChild(#cl1); } )?
				)
			)
	;


ctorCall [object w]
	:	#( THIS   elist[w]  )
	|	#( BASE   elist[w]  )
	;

arrayIndex! [object w]
	:	#(ELEMENT_ACCESS_EXPR e:expr[w] idx:elist[w] )   // keving: Strips off one rank
		{	
			ASTNode retAST = null;
			TypeRep at = #e.DotNetType;
			if (at.TypeName.EndsWith("[]") || at.TypeName == "System.Array")
			{
			    // A real array, keep array notation
				ArrayList ms = (ArrayList)at.MethodsD["GetValue"];
				retAST = #( [ELEMENT_ACCESS_EXPR], #e, #idx);
				retAST.DotNetType = ((MethodRep)ms[0]).Return;
		    }
		    else
		    {
		       // TODO: Setter or Getter?
			   if ( !SetterContext(##_in) )
			   {
			      retAST = ResolveMethod( #( [INVOCATION_EXPR], #( [MEMBER_ACCESS_EXPR], astFactory.dupTree(#e), 
			                                                                             [IDENTIFIER, "get___idx"]), 
			                                                    astFactory.dupTree(#idx)) ); 
			      if (retAST == null)
			      {
				      retAST = #( [ELEMENT_ACCESS_EXPR], #e, #idx);
				      retAST.DotNetType = mkType("System.Object");
			      }
			   }   
			   else
			   {
				   retAST = #( [ELEMENT_ACCESS_EXPR], #e, #idx);
				   retAST.DotNetType = mkType("System.Object");
			   }
		     }
		     ## = retAST;
		 } 
	;

constant [object w]
    :   INT_LITERAL			{ ##.DotNetType = mkType("System.Int32"); }	
    |   CHAR_LITERAL		{ ##.DotNetType = mkType("System.Char"); }		
    |   STRING_LITERAL		{ ##.DotNetType = mkType("System.String"); }		
    |   NUM_FLOAT			{ ##.DotNetType = mkType("System.Single"); }	
    |   DOUBLE_LITERAL		{ ##.DotNetType = mkType("System.Double"); }	
    |   FLOAT_LITERAL		{ ##.DotNetType = mkType("System.Single"); }	
    |   LONG_LITERAL		{ ##.DotNetType = mkType("System.Int64"); }
    |   ULONG_LITERAL		{ ##.DotNetType = mkType("System.UInt64"); }
    |   DECIMAL_LITERAL		{ ##.DotNetType = mkType("System.Decimal"); }			
    ;

newExpression [object w]
	:!	#(	OBJ_CREATE_EXPR				 
			t:typeSpec[w]
			a:elist[w]  { 
							ASTNode kosherInp = #( [OBJ_CREATE_EXPR], #t, #a);
							ASTNode retAST = null;
							retAST = ResolveNewObj( kosherInp );
							if (retAST == null)
							{
							    retAST = kosherInp;
							    retAST.DotNetType = #t.DotNetType;
							}
							## = retAST; 
						}
			/* keving:  This was in the pretty printer, but it is never generated and I can't find reference to it
			( 
					objBlock[w]
			  
			)?
			*/			
		) 
	|   #(	ARRAY_CREATE_EXPR				 
			at:typeSpec[w] 
			 ( arrayInitializer[w] //rankSpecifiers[w]!
			 |  elist[w]  
			   rankSpecifiers[w] ( arrayInitializer[w] )?
			 ) 
		 ) { ##.DotNetType = #at.DotNetType; } 
	;

// newArrayDeclarator [object w]
// 	:	#( ARRAY_DECLARATOR (newArrayDeclarator[w])? (expression[w])? )
//	;
