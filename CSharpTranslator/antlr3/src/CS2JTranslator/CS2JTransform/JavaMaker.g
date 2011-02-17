/*
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

// JavaMaker.g
//
// Convert C# parse tree to a Java parse tree
//
tree grammar JavaMaker;

options {
    tokenVocab=cs;
    ASTLabelType=CommonTree;
    language=CSharp2;
    superClass='Twiglet.CS2J.Translator.Transform.CommonWalker';
    output=AST;
}

// A scope to keep track of the namespaces available at any point in the program
scope NSContext {
    int filler;
    string currentNS;

    // namespaces in scope
    List<string> namespaces;

    // Alias map: these two lists are actually a map from alias to namespace
    // so aliases[i] -> namespaces[i]
    List<string> aliasKeys;
    List<string> aliasNamespaces;
}

// A scope to keep track of the current type context
scope TypeContext {
    string typeName;
}

@namespace { Twiglet.CS2J.Translator.Transform }

@header
{
    using System;
    using System.Globalization;
}

@members
{

    // Since a CS file may comtain multiple top level types (and so generate multiple Java
    // files) we build a map from type name to AST for each top level type
    // We also build a lit of type names so that we can maintain the order (so comments
    // at the end of the file will get included when we emit the java for the last type)
    public IDictionary<string, CUnit> CUMap { get; set; }
    public IList<string> CUKeys { get; set; }

    protected string ParentNameSpace {
        get {
            return ((NSContext_scope)$NSContext.ToArray()[1]).currentNS;
        }
    }

    protected List<string> CollectSearchPath {
        get {
            List<string> ret = new List<string>();
            Object[] nsCtxtArr = $NSContext.ToArray();
            for (int i = nsCtxtArr.Length - 1; i >= 0; i--) {
                foreach (string v in ((NSContext_scope)nsCtxtArr[i]).namespaces) {
                    ret.Add(v);
                }
            }
            return ret;
        }
    }

    protected List<string> CollectAliasKeys {
        get {
            List<string> ret = new List<string>();
            Object[] nsCtxtArr = $NSContext.ToArray();
            for (int i = nsCtxtArr.Length - 1; i >= 0; i--) {
                foreach (string v in ((NSContext_scope)nsCtxtArr[i]).aliasKeys) {
                    ret.Add(v);
                }
            }
            return ret;
        }
    }

    protected List<string> CollectAliasNamespaces {
        get {
            List<string> ret = new List<string>();
            Object[] nsCtxtArr = $NSContext.ToArray();
            for (int i = nsCtxtArr.Length - 1; i >= 0; i--) {
                foreach (string v in ((NSContext_scope)nsCtxtArr[i]).aliasNamespaces) {
                    ret.Add(v);
                }
            }
            return ret;
        }
    }

    // TREE CONSTRUCTION
    protected CommonTree mkPayloadList(List<string> payloads) {
        CommonTree root = (CommonTree)adaptor.Nil;

        foreach (string p in payloads) {
            adaptor.AddChild(root, (CommonTree)adaptor.Create(PAYLOAD, p));
        }
        return root;
    }

    protected CommonTree mangleModifiersForType(CommonTree modifiers) {
        if (modifiers == null || modifiers.Children == null)
            return modifiers;
        CommonTree stripped = (CommonTree)modifiers.DupNode();
        for (int i = 0; i < modifiers.Children.Count; i++) {
            if (((CommonTree)modifiers.Children[i]).Token.Text != "static") {
                adaptor.AddChild(stripped, modifiers.Children[i]);
            }
        }
        return stripped;
    }

    protected CommonTree addConstModifiers(IToken tok, List<string> filter) {
        CommonTree root = (CommonTree)adaptor.Nil;

        if (filter == null || !filter.Contains("static") )
        {
            adaptor.AddChild(root, (CommonTree)adaptor.Create(STATIC, tok, "static"));
        }
        if (filter == null || !filter.Contains("final")) 
        {
            adaptor.AddChild(root, (CommonTree)adaptor.Create(FINAL, tok, "final"));
        }
        root = (CommonTree)adaptor.RulePostProcessing(root);
        return root;
    }

// for ["conn", "conn1", "conn2"] generate:
//
//                   if (conn != null)
//                      ((IDisposable)conn).Dispose();
// 
//                   
//                  if (conn2 != null)
//                      ((IDisposable)conn2).Dispose();
// 
//                   
//                  if (conn3 != null)
//                      ((IDisposable)conn3).Dispose();
// used in the finally block of the using translation
    protected CommonTree addDisposeVars(IToken tok, List<string> vars) {
                	
        CommonTree root = (CommonTree)adaptor.Nil;

        foreach (string var in vars) {
        
            CommonTree root_1 = (CommonTree)adaptor.Nil;
            root_1 = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(IF, tok, "if"), root_1);

            CommonTree root_2 = (CommonTree)adaptor.Nil;
            root_2 = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(NOT_EQUAL, tok, "!="), root_2);

            adaptor.AddChild(root_2, (CommonTree)adaptor.Create(IDENTIFIER, tok, var));
            adaptor.AddChild(root_2, (CommonTree)adaptor.Create(NULL, tok, "null"));

            adaptor.AddChild(root_1, root_2);

            adaptor.AddChild(root_1, (CommonTree)adaptor.Create(SEP, "SEP"));

            root_2 = (CommonTree)adaptor.Nil;
            root_2 = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(APPLY, tok, "APPLY"), root_2);

            CommonTree root_3 = (CommonTree)adaptor.Nil;
            root_3 = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(DOT, tok, "."), root_3);

            CommonTree root_4 = (CommonTree)adaptor.Nil;
            root_4 = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(CAST_EXPR, tok, "CAST"), root_4);

            CommonTree root_5 = (CommonTree)adaptor.Nil;
            root_5 = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(TYPE, tok, "TYPE"), root_5);

            adaptor.AddChild(root_5, (CommonTree)adaptor.Create(IDENTIFIER, tok, "IDisposable"));

            adaptor.AddChild(root_4, root_5);

            adaptor.AddChild(root_4, (CommonTree)adaptor.Create(IDENTIFIER, tok, var));

            adaptor.AddChild(root_3, root_4);

            adaptor.AddChild(root_3, (CommonTree)adaptor.Create(IDENTIFIER, tok, "Dispose"));

            adaptor.AddChild(root_2, root_3);

            adaptor.AddChild(root_1, root_2);

            adaptor.AddChild(root_1, (CommonTree)adaptor.Create(SEMI, tok, ";"));

            adaptor.AddChild(root, root_1);
        }

        return (CommonTree)adaptor.RulePostProcessing(root);
    }

    // TODO:  Read reserved words from a file so that they can be extended by customer
    private readonly static string[] javaReserved = new string[] { "int", "protected", "package" };
    
    protected string fixBrokenId(string id)
    {
        // Console.WriteLine(id);
        foreach (string k in javaReserved)
        {
            if (k == id) 
            {
                return "__" + id;
            }
        }
        return id;
    }

    // Map of C# built in types to Java equivalents
    Dictionary<string, string> predefined_type_map = new Dictionary<string, string>()
    {
        {"bool", "boolean"},
        {"decimal", "double"},
        {"object", "Object"},
        {"string", "String"}
    };

    protected CommonTree mkHole() {
        return mkHole(null);
    }

    protected CommonTree mkHole(IToken tok) {
        return (CommonTree)adaptor.Create(KGHOLE, tok, "KGHOLE");
    }

    // counter to ensure that the catch vars we introduce are unique 
    protected int dummyCatchVarCtr = 0;

    protected int newVarCtr = 0;

    protected CommonTree dupTree(CommonTree t) {
        return (CommonTree)adaptor.DupTree(t);
    }

}

/********************************************************************************************
                          Parser section
*********************************************************************************************/

///////////////////////////////////////////////////////

public compilation_unit
scope NSContext;
@init {
    $NSContext::currentNS = "";
    $NSContext::namespaces = new List<string>();
    $NSContext::aliasKeys = new List<string>();
    $NSContext::aliasNamespaces = new List<string>();
}
:
	namespace_body;

namespace_declaration
scope NSContext;
@init {
    $NSContext::currentNS = "";
    $NSContext::namespaces = new List<string>();
    $NSContext::aliasKeys = new List<string>();
    $NSContext::aliasNamespaces = new List<string>();
}:
	'namespace'   qi=qualified_identifier
    {     
        // extend parent namespace
        $NSContext::currentNS = this.ParentNameSpace + $qi.thetext;
        $NSContext::namespaces.Add($NSContext::currentNS);
    }
    namespace_block   ';'? ;
namespace_block:
	'{'   namespace_body   '}' ;
namespace_body:
	extern_alias_directives?   using_directives?   global_attributes?   namespace_member_declarations? ;
extern_alias_directives:
	extern_alias_directive+ ;
extern_alias_directive:
	e='extern'   'alias'   i=identifier  ';' { Warning($e.line, "[UNSUPPORTED] External Alias " + $i.text); } ;
using_directives:
	using_directive+ ;
using_directive:
	(using_alias_directive
	| using_namespace_directive) ;
using_alias_directive:
	'using'	  identifier   '='   namespace_or_type_name   ';' 
        {$NSContext::aliasKeys.Add($identifier.text);$NSContext::aliasNamespaces.Add($namespace_or_type_name.thetext); } ;
using_namespace_directive:
	'using'   namespace_name   ';' {$NSContext::namespaces.Add($namespace_name.thetext); };
namespace_member_declarations:
	namespace_member_declaration+ ;
namespace_member_declaration
@init { string ns = $NSContext::currentNS; 
        bool isCompUnit = false;
}
@after {
    if (isCompUnit) {
        CUMap.Add(ns+"."+$ty.name, new CUnit($namespace_member_declaration.tree,CollectSearchPath,CollectAliasKeys,CollectAliasNamespaces)); 
        CUKeys.Add(ns+"."+$ty.name);
    }; 
}
:
	namespace_declaration
	| attributes?   modifiers?   ty=type_declaration[$attributes.tree, mangleModifiersForType($modifiers.tree)]  { isCompUnit = true; } ->  ^(PACKAGE[$ty.start.Token, "package"] PAYLOAD[ns] $ty);
// type_declaration is only called at the top level, so each of the types declared
// here will become a Java compilation unit (and go to its own file)
type_declaration[CommonTree atts, CommonTree mods] returns [string name]
:
    ('partial') => p='partial'!  { Warning($p.line, "[UNSUPPORTED] 'partial' definition"); }  
                                (pc=class_declaration[$atts, $mods] { $name=$pc.name; }
								| ps=struct_declaration[$atts, $mods] { $name=$ps.name; }
								| pi=interface_declaration[$atts, $mods] { $name=$pi.name; }) 
	| c=class_declaration[$atts, $mods] { $name=$c.name; }
	| s=struct_declaration[$atts, $mods] { $name=$s.name; }
	| i=interface_declaration[$atts, $mods] { $name=$i.name; }
	| e=enum_declaration[$atts, $mods] { $name=$e.name; }
	| d=delegate_declaration[$atts, $mods] { $name=$d.name; }
    ;
// Identifiers
qualified_identifier returns [string thetext]:
	i1=identifier { $thetext = $i1.text; } ('.' ip=identifier { $thetext += "." + $ip.text; } )*;
namespace_name returns [string thetext]
	: namespace_or_type_name { $thetext = $namespace_or_type_name.thetext; };

modifiers returns [List<string> modList]
@init {
    $modList = new List<string>();
}:
	 (modifier { if ($modifier.tree != null) $modList.Add( $modifier.tree.Text); })+ ;
modifier: 
	'new' -> /* No new in Java*/ | 'public' | 'protected' | 'private' | 'internal' ->  /* translate to package-private */| 'unsafe' ->  | 'abstract' | 'sealed' -> FINAL["final"] | 'static'
	| 'readonly' -> /* no equivalent in C# (this is like a const that can be initialized separately in the constructor) */ | 'volatile' | e='extern'  { Warning($e.line, "[UNSUPPORTED] 'extern' modifier"); }  | 'virtual' -> | 'override' -> /* not in Java, maybe convert to override annotation */;

class_member_declaration:
	a=attributes?
	m=modifiers?
	( c='const'   ct=type   constant_declarators   ';' -> ^(FIELD[$c.token, "FIELD"] $a? $m? { addConstModifiers($c.token, $m.modList) } $ct constant_declarators)
	| ev=event_declaration	-> ^(EVENT[$ev.start.Token, "EVENT"] $a? $m? $ev)
	| p='partial' { Warning($p.line, "[UNSUPPORTED] 'partial' definition"); } (v1=void_type m3=method_declaration[$a.tree, $m.tree, $m.modList, $v1.tree, $v1.text] -> $m3 
			   | pi=interface_declaration[$a.tree, $m.tree] -> $pi
			   | pc=class_declaration[$a.tree, $m.tree] -> $pc
			   | ps=struct_declaration[$a.tree, $m.tree] -> $ps)
	| i=interface_declaration[$a.tree, $m.tree] -> $i
	| v2=void_type   m1=method_declaration[$a.tree, $m.tree, $m.modList, $v2.tree, $v2.text] -> $m1 
	| t=type ( (member_name  type_parameter_list? '(') => m2=method_declaration[$a.tree, $m.tree, $m.modList, $t.tree, $t.text] -> $m2
		   | (member_name   '{') => pd=property_declaration[$a.tree, $m.tree, $t.tree] -> $pd
		   | (member_name   '.'   'this') => type_name '.' ix1=indexer_declaration[$a.tree, $m.tree, $t.tree] -> $ix1
		   | ix2=indexer_declaration[$a.tree, $m.tree, $t.tree]	-> $ix2 //this
	       | field_declaration     -> ^(FIELD[$t.start.Token, "FIELD"] $a? $m? $t field_declaration) // qid
	       | operator_declaration -> ^(OPERATOR[$t.start.Token, "OPERATOR"] $a? $m? $t operator_declaration)
	       )
//	common_modifiers// (method_modifiers | field_modifiers)
	
	| cd=class_declaration[$a.tree, $m.tree] -> $cd
	| sd=struct_declaration[$a.tree, $m.tree] -> $sd
	| ed=enum_declaration[$a.tree, $m.tree] -> $ed
	| dd=delegate_declaration[$a.tree, $m.tree] -> $dd
	| co3=conversion_operator_declaration -> ^(CONVERSION_OPERATOR[$co3.start.Token, "CONVERSION"] $a? $m? $co3)
	| con3=constructor_declaration[$a.tree, $m.tree, $m.modList]	-> $con3
	| de3=destructor_declaration -> $de3
	) 
	;

primary_expression: 
	('this'    brackets[null]) => (t='this' -> $t)  (b1=brackets[$primary_expression.tree] -> $b1) (pp1=primary_expression_part[$primary_expression.tree] -> $pp1) *
	| ('base'   brackets[null]) => (b='base' -> SUPER[$b.token, "super"])  (b2=brackets[$primary_expression.tree] -> $b2) (pp2=primary_expression_part[$primary_expression.tree] -> $pp2) *
	| (primary_expression_start -> primary_expression_start)   (pp3=primary_expression_part[$primary_expression.tree] -> $pp3 )*
// keving:TODO fixup
	| 'new' (   (object_creation_expression   ('.'|'->'|'[')) => 
					(oc1=object_creation_expression -> $oc1)   (pp4=primary_expression_part[ $primary_expression.tree ] -> $pp4 )+ 		// new Foo(arg, arg).Member
				// try the simple one first, this has no argS and no expressions
				// symantically could be object creation
				| (delegate_creation_expression) => delegate_creation_expression -> delegate_creation_expression // new FooDelegate (MyFunction)
				| oc2=object_creation_expression -> $oc2
				| anonymous_object_creation_expression -> anonymous_object_creation_expression)							// new {int X, string Y} 
	| sizeof_expression						// sizeof (struct)
	| checked_expression            		// checked (...
	| unchecked_expression          		// unchecked {...}
	| default_value_expression      		// default
	| anonymous_method_expression			// delegate (int foo) {}
	;

primary_expression_start:
	predefined_type            
	| (identifier    generic_argument_list) => identifier   generic_argument_list
	| identifier ((c='::'^   identifier { Warning($c.line, "[UNSUPPORTED] external aliases are not yet supported"); })?)!
	| 'this' 
	| b='base' -> SUPER[$b.token, "super"]
	| paren_expression
	| typeof_expression             // typeof(Foo).Name
	| literal
	;

primary_expression_part [CommonTree lhs]:
	 access_identifier[$lhs]
	| brackets_or_arguments[$lhs] 
	| p='++' -> ^(POSTINC[$p.token, "++"] { dupTree($lhs) } )
	| m='--' -> ^(POSTDEC[$m.token, "--"] { dupTree($lhs) } )
    ;
access_identifier [CommonTree lhs]:
	access_operator   type_or_generic -> ^(access_operator { dupTree($lhs) } type_or_generic);
access_operator:
	'.'  |  '->' ;
brackets_or_arguments [CommonTree lhs]:
	brackets[$lhs] | arguments[$lhs] ;
brackets [CommonTree lhs]:
	'['   expression_list?   ']' -> ^(INDEX { dupTree($lhs) } expression_list?);	
// keving: TODO: drop this.
paren_expression:	
	'('   expression   ')' -> ^(PARENS expression);
arguments [CommonTree lhs]: 
	'('   argument_list?   ')' -> ^(APPLY { dupTree($lhs) } argument_list?);
argument_list: 
	a1=argument (',' an+=argument)* -> ^(ARGS[$a1.start.Token,"ARGS"] $a1 $an*);
// 4.0
argument:
	argument_name   argument_value
	| argument_value;
argument_name:
	identifier   ':';
argument_value: 
	expression 
	| ref_variable_reference 
	| 'out'   variable_reference ;
ref_variable_reference:
	'ref' 
		(('('   type   ')') =>   '('   type   ')'   (ref_variable_reference | variable_reference)   // SomeFunc(ref (int) ref foo)
																									// SomeFunc(ref (int) foo)
		| variable_reference);	// SomeFunc(ref foo)
// lvalue
variable_reference:
	expression;
rank_specifiers: 
	rank_specifier+ ;        
// convert dimension separators into additional dimensions, so [,,] -> [] [] []
rank_specifier: 
	o='['   dim_separators?   c=']' -> $o $c dim_separators?;
dim_separators
@init {
    CommonTree ret = (CommonTree)adaptor.Nil;
}
@after {
    $dim_separators.tree = ret;
}: 
        (c=',' { adaptor.AddChild(ret, adaptor.Create(OPEN_BRACKET, $c.token, "["));adaptor.AddChild(ret, adaptor.Create(CLOSE_BRACKET, $c.token, "]")); })+ -> ;

delegate_creation_expression: 
	// 'new'   
	t1=type_name   '('   t2=type_name   ')' -> ^(NEW[$t1.start.Token, "new"] ^(TYPE[$t1.start.Token, "TYPE"] $t1) ^(ARGS[$t2.start.Token, "ARGS"] $t2));
anonymous_object_creation_expression: 
	// 'new'
	anonymous_object_initializer ;
anonymous_object_initializer: 
	'{'   (member_declarator_list   ','?)?   '}';
member_declarator_list: 
	member_declarator  (',' member_declarator)* ; 
member_declarator: 
	qid   ('='   expression)? ;
primary_or_array_creation_expression:
	(array_creation_expression) => array_creation_expression
	| primary_expression 
	;
// new Type[2] { }
array_creation_expression
@init {
    bool removeDimensions = false;
}
@after {
    if (removeDimensions) {
        if ($array_creation_expression.tree != null && 
            adaptor.GetChildCount($array_creation_expression.tree) > 3 &&
            adaptor.GetType(adaptor.GetChild($array_creation_expression.tree, 1)) == OPEN_BRACKET) {
            // Delete until CLOSE_BRACKET
            while (adaptor.GetType(adaptor.GetChild($array_creation_expression.tree, 2)) != CLOSE_BRACKET) {
                adaptor.DeleteChild($array_creation_expression.tree, 2);
            }
            // push open / close bracket into type.
            CommonTree type = (CommonTree)adaptor.GetChild($array_creation_expression.tree, 0);
            adaptor.AddChild(type, adaptor.DupTree(adaptor.GetChild($array_creation_expression.tree, 1)));
            adaptor.AddChild(type, adaptor.DupTree(adaptor.GetChild($array_creation_expression.tree, 2)));
            adaptor.DeleteChild($array_creation_expression.tree, 2);
            adaptor.DeleteChild($array_creation_expression.tree, 1);

        }
    }
}:
	n='new'^   
		(type   ('['   expression_list   ']'   
					( rank_specifiers?   (array_initializer { removeDimensions = true; /* If an initializer is provided then drop the dimensions */} )?	// new int[4]
					// | invocation_part*
					| ( ((arguments[null]   ('['|'.'|'->')) => arguments[ (CommonTree)adaptor.Create(KGHOLE, "KGHOLE") ]   invocation_part)// new object[2].GetEnumerator()
					  | invocation_part)*   arguments[ (CommonTree)adaptor.Create(KGHOLE, "KGHOLE") ]
					)							// new int[4]()
				| array_initializer		
				)
		| rank_specifier   // [,]
			(array_initializer	// var a = new[] { 1, 10, 100, 1000 }; // int[]
		    )
		) ;
array_initializer:
	'{'   variable_initializer_list?   ','?   '}' ;
variable_initializer_list:
	variable_initializer (',' variable_initializer)* ;
variable_initializer:
	expression	| array_initializer ;
sizeof_expression:
	'sizeof'^   '('!   unmanaged_type   ')'!;
checked_expression: 
	'checked'^   '('!   expression   ')'! ;
unchecked_expression: 
	'unchecked'^   '('!   expression   ')'! ;
default_value_expression: 
	'default'^   '('!   type   ')'! ;
anonymous_method_expression:
	'delegate'^   explicit_anonymous_function_signature?   block;
explicit_anonymous_function_signature:
	'('   explicit_anonymous_function_parameter_list?   ')' ;
explicit_anonymous_function_parameter_list:
	explicit_anonymous_function_parameter   (','   explicit_anonymous_function_parameter)* ;	
explicit_anonymous_function_parameter:
	anonymous_function_parameter_modifier?   type   identifier;
anonymous_function_parameter_modifier:
	'ref' | 'out';


///////////////////////////////////////////////////////
object_creation_expression: 
	// 'new'
	type   
		( '('   argument_list?   ')'   o1=object_or_collection_initializer?  -> ^(NEW[$type.start.Token, "new"] type argument_list? $o1?)
		  | o2=object_or_collection_initializer -> ^(NEW[$type.start.Token, "new"] type $o2)) 
	;
object_or_collection_initializer: 
	'{'  (object_initializer 
		| collection_initializer) ;
collection_initializer: 
	element_initializer_list   ','?   '}' ;
element_initializer_list: 
	element_initializer  (',' element_initializer)* ;
element_initializer: 
	non_assignment_expression 
	| '{'   expression_list   '}' ;
// object-initializer eg's
//	Rectangle r = new Rectangle {
//		P1 = new Point { X = 0, Y = 1 },
//		P2 = new Point { X = 2, Y = 3 }
//	};
// TODO: comma should only follow a member_initializer_list
object_initializer: 
	member_initializer_list?   ','?   '}' ;
member_initializer_list: 
	member_initializer  (',' member_initializer) ;
member_initializer: 
	identifier   '='   initializer_value ;
initializer_value: 
	expression 
	| object_or_collection_initializer ;

///////////////////////////////////////////////////////

typeof_expression: 
	'typeof'^   '('!   ((unbound_type_name) => unbound_type_name
					  | type 
					  | void_type)   ')'! ;
// unbound type examples
//foo<bar<X<>>>
//bar::foo<>
//foo1::foo2.foo3<,,>
unbound_type_name:		// qualified_identifier v2
//	unbound_type_name_start unbound_type_name_part* ;
	unbound_type_name_start   
		(((generic_dimension_specifier   '.') => generic_dimension_specifier   unbound_type_name_part)
		| unbound_type_name_part)*   
			generic_dimension_specifier
	;

unbound_type_name_start:
	identifier ('::' identifier)?;
unbound_type_name_part:
	'.'   identifier;
generic_dimension_specifier: 
	'<'   commas?   '>' ;
commas: 
	','+ ; 

///////////////////////////////////////////////////////
//	Type Section
///////////////////////////////////////////////////////

type_name returns [string thetext]: 
	namespace_or_type_name { $thetext = $namespace_or_type_name.thetext; };
namespace_or_type_name returns [string thetext]: 
	 t1=type_or_generic  { $thetext=t1.type+formatTyargs($t1.generic_arguments); } ('::'^ tc=type_or_generic { $thetext+="::"+tc.type+formatTyargs($tc.generic_arguments); })? ('.'^   tn=type_or_generic { $thetext+="."+tn.type+formatTyargs($tn.generic_arguments); } )* ;
type_or_generic returns [string type, List<string> generic_arguments]
@init {
    $generic_arguments = new List<string>();
}
@after{
    $type = $t.text;
}:
	(identifier   generic_argument_list) => t=identifier   ga=generic_argument_list { $generic_arguments = $ga.tyargs; }
	| t=identifier ;

// keving: as far as I can see this is (<interfacename>.)?identifier (<tyargs>)? at lease for C# 3.0 and less.
qid returns [string name, List<string> tyargs]:		// qualified_identifier v2
	(qs=qid_start -> $qs)  (qp=qid_part[$qid.tree] -> $qp)* { $name=$qid_start.name; $tyargs = $qid_start.tyargs; }
	;
qid_start returns [string name, List<string> tyargs]:
	predefined_type { $name = $predefined_type.thetext; }
	| (identifier    generic_argument_list)	=> identifier   generic_argument_list { $name = $identifier.text; $tyargs = $generic_argument_list.tyargs; } 
//	| 'this'
//	| 'base'
	| i1=identifier  { $name = $i1.text; } ('::'   inext=identifier { $name+="::" + $inext.text; })?
	| literal { $name = $literal.text; }
	;		// 0.ToString() is legal


qid_part[CommonTree lhs]:
	access_identifier[ $lhs ] ;

generic_argument_list returns [List<string> tyargs]
@after { 
    $tyargs = $ta.tyargs;
}
: 
	'<'   ta=type_arguments   '>' ;
type_arguments returns [List<string> tyargs]
@init {
    $tyargs = new List<string>();
}
: 
	t1=type { $tyargs.Add($t1.thetext); } (',' tn=type { $tyargs.Add($tn.thetext); })* ;

type returns [string thetext]:
         ((predefined_type | type_name)  rank_specifiers) => (p1=predefined_type { $thetext = $p1.thetext; } | tn1=type_name { $thetext = $tn1.thetext; })   rs=rank_specifiers  { $thetext += $rs.text; } (s1+='*' { $thetext += "*"; })* -> ^(TYPE $p1? $tn1? $rs $s1*)
       | ((predefined_type | type_name)  ('*'+ | '?')) => (p2=predefined_type { $thetext = $p2.thetext; } | tn2=type_name { $thetext = $tn2.thetext; })   ((s2+='*' { $thetext += "*"; })+ | o2='?' { $thetext += "?"; }) -> ^(TYPE $p2? $tn2? $s2* $o2?)
       | (p3=predefined_type { $thetext = $p3.thetext; } | tn3=type_name { $thetext = $tn3.thetext; }) -> ^(TYPE $p3? $tn3?)
       | v='void' { $thetext = "System.Void"; } (s+='*' { $thetext += "*"; })+  -> ^(TYPE[$v.token, "TYPE"] $v $s+)
       ;
non_nullable_type:
	(p=predefined_type | t=type_name) rs=rank_specifiers? (s+='*')* ->  ^(TYPE["TYPE"] $p? $t? $rs? $s*)
       | v='void' (s+='*')+  -> ^(TYPE[$v.token,"TYPE"] $v $s+)
       ;
non_array_type:
	type;
array_type:
	type;
unmanaged_type:
	type;
class_type:
	type;
pointer_type:
	type;


///////////////////////////////////////////////////////
//	Statement Section
///////////////////////////////////////////////////////
block:
	';'
	| '{'   statement_list?   '}';
statement_list:
	statement+ ;
	
///////////////////////////////////////////////////////
//	Expression Section
///////////////////////////////////////////////////////	
expression: 
	(unary_expression   assignment_operator) => assignment	
	| non_assignment_expression
	;
expression_list:
	expression  (','   expression)* ;
assignment:
	unary_expression   assignment_operator   expression ;
unary_expression: 
	//('(' arguments ')' ('[' | '.' | '(')) => primary_or_array_creation_expression
    (cast_expression) => cast_expression
	| primary_or_array_creation_expression -> primary_or_array_creation_expression
	| p='+'   unary_expression -> ^(MONOPLUS[$p.token,"+"] unary_expression) 
	| m='-'   unary_expression -> ^(MONOMINUS[$m.token, "-"] unary_expression) 
	| n='!'   unary_expression -> ^(MONONOT[$n.token, "!"] unary_expression) 
	| t='~'   unary_expression -> ^(MONOTWIDDLE[$t.token, "~"] unary_expression) 
	| pre_increment_expression -> pre_increment_expression
	| pre_decrement_expression -> pre_decrement_expression
	| pointer_indirection_expression -> pointer_indirection_expression
	| addressof_expression -> addressof_expression 
	;
cast_expression:
//	//'('   type   ')'   unary_expression ; 
	l='('   type   ')'   unary_expression -> ^(CAST_EXPR[$l.token, "CAST"] type unary_expression);
assignment_operator:
	'=' | '+=' | '-=' | '*=' | '/=' | '%=' | '&=' | '|=' | '^=' | '<<=' | r='>' '>=' -> RIGHT_SHIFT_ASSIGN[$r.token, ">>="] ;
pre_increment_expression: 
	s='++'   unary_expression -> ^(PREINC[$s.token, "++"] unary_expression) ;
pre_decrement_expression: 
	s='--'   unary_expression -> ^(PREDEC[$s.token, "--"] unary_expression);
pointer_indirection_expression:
	s='*'   unary_expression -> ^(MONOSTAR[$s.token, "*"] unary_expression);
addressof_expression:
	a='&'   unary_expression -> ^(ADDRESSOF[$a.token, "&"] unary_expression);

non_assignment_expression:
	//'non ASSIGNment'
	(anonymous_function_signature   '=>')	=> lambda_expression
	| (query_expression) => query_expression 
	| conditional_expression
	;

///////////////////////////////////////////////////////
//	Conditional Expression Section
///////////////////////////////////////////////////////

multiplicative_expression:
	(u1=unary_expression -> $u1) ((op='*'|op='/'|op='%')  un=unary_expression -> ^($op $multiplicative_expression $un) )*	;
additive_expression:
	multiplicative_expression (('+'|'-')^   multiplicative_expression)* ;
// >> check needed (no whitespace)
shift_expression:
    (a1=additive_expression -> $a1) ((so='<<' a3=additive_expression -> ^($so $shift_expression $a3))
                            | (r='>' '>' a2=additive_expression -> ^(RIGHT_SHIFT[$r.token, ">>"] $shift_expression $a2)) 
                           )* ;
relational_expression:
	(s1=shift_expression -> $s1) 
		(	((o='<'|o='>'|o='>='|o='<=')	s2=shift_expression -> ^($o $relational_expression $s2))
			| (i='is'  t=non_nullable_type -> ^(INSTANCEOF[$i.Token,"instanceof"] $relational_expression $t) 
                | i1='as' t1=non_nullable_type -> ^(COND_EXPR[$i1.Token, "?:"] 
                                                        ^(INSTANCEOF[$i1.Token,"instanceof"] { dupTree($relational_expression.tree) } { dupTree($t1.tree) } ) 
                                                        ^(CAST_EXPR[$i1.Token, "(cast)"] { dupTree($t1.tree) } { dupTree($relational_expression.tree) }) 
                                                        ^(CAST_EXPR[$i1.Token, "(cast)"] { dupTree($t1.tree) } NULL[$i1.Token, "null"])))
		)* ;
equality_expression:
	relational_expression
	   (('=='|'!=')^   relational_expression)* ;
and_expression:
	equality_expression ('&'^   equality_expression)* ;
exclusive_or_expression:
	and_expression ('^'^   and_expression)* ;
inclusive_or_expression:
	exclusive_or_expression   ('|'^   exclusive_or_expression)* ;
conditional_and_expression:
	inclusive_or_expression   ('&&'^   inclusive_or_expression)* ;
conditional_or_expression:
	conditional_and_expression  ('||'^   conditional_and_expression)* ;

null_coalescing_expression:
	(e1=conditional_or_expression -> $e1)  (qq='??'   e2=conditional_or_expression -> ^(COND_EXPR[$qq.token, "?:"]
                                                                                          ^(NOT_EQUAL[$qq.token, "!="] { dupTree($null_coalescing_expression.tree) } NULL[$qq.Token, "null"])
                                                                                          { dupTree($null_coalescing_expression.tree) }
                                                                                          { dupTree($e2.tree) })
                                           )* ;
conditional_expression:
     (ne=null_coalescing_expression  -> $ne) (q='?'   te=expression   ':'   ee=expression ->  ^(COND_EXPR[$q.token, "?:"] $conditional_expression $te $ee))? ;
//	(null_coalescing_expression   '?'   expression   ':') => e1=null_coalescing_expression   q='?'   e2=expression   ':'   e3=expression -> ^(COND_EXPR[$q.token, "?:"] $e1 $e2 $e3)
//    | null_coalescing_expression   ;
      
///////////////////////////////////////////////////////
//	lambda Section
///////////////////////////////////////////////////////
lambda_expression:
	anonymous_function_signature   '=>'   anonymous_function_body;
anonymous_function_signature:
	'('	(explicit_anonymous_function_parameter_list
		| implicit_anonymous_function_parameter_list)?	')'
	| implicit_anonymous_function_parameter_list
	;
implicit_anonymous_function_parameter_list:
	implicit_anonymous_function_parameter   (','   implicit_anonymous_function_parameter)* ;
implicit_anonymous_function_parameter:
	identifier;
anonymous_function_body:
	expression
	| block ;

///////////////////////////////////////////////////////
//	LINQ Section
///////////////////////////////////////////////////////
query_expression:
	from_clause   query_body ;
query_body:
	// match 'into' to closest query_body
	query_body_clauses?   select_or_group_clause   (('into') => query_continuation)? ;
query_continuation:
	'into'   identifier   query_body;
query_body_clauses:
	query_body_clause+ ;
query_body_clause:
	from_clause
	| let_clause
	| where_clause
	| join_clause
	| orderby_clause;
from_clause:
	'from'   type?   identifier   'in'   expression ;
join_clause:
	'join'   type?   identifier   'in'   expression   'on'   expression   'equals'   expression ('into' identifier)? ;
let_clause:
	'let'   identifier   '='   expression;
orderby_clause:
	'orderby'   ordering_list ;
ordering_list:
	ordering   (','   ordering)* ;
ordering:
	expression    ordering_direction
	;
ordering_direction:
	'ascending'
	| 'descending' ;
select_or_group_clause:
	select_clause
	| group_clause ;
select_clause:
	'select'   expression ;
group_clause:
	'group'   expression   'by'   expression ;
where_clause:
	'where'   boolean_expression ;
boolean_expression:
	expression;

///////////////////////////////////////////////////////
// B.2.13 Attributes
///////////////////////////////////////////////////////
global_attributes: 
	global_attribute+ ;
global_attribute: 
	'['   global_attribute_target_specifier   attribute_list   ','?   ']' ;
global_attribute_target_specifier: 
	global_attribute_target   ':' ;
global_attribute_target: 
	'assembly' | 'module' ;
attributes: 
	attribute_sections ;
attribute_sections: 
	attribute_section+ ;
attribute_section: 
	'['   attribute_target_specifier?   attribute_list   ','?   ']' ;
attribute_target_specifier: 
	attribute_target   ':' ;
attribute_target: 
	'field' | 'event' | 'method' | 'param' | 'property' | 'return' | 'type' ;
attribute_list: 
	attribute (',' attribute)* ; 
attribute: 
	type_name   attribute_arguments? ;
// TODO:  allows a mix of named/positional arguments in any order
attribute_arguments: 
	'('   (')'										// empty
		   | (positional_argument   ((','   identifier   '=') => named_argument
		   							 |','	positional_argument)*
			  )	')'
			) ;
positional_argument_list: 
	a1=positional_argument (',' an+=positional_argument)* -> ^(ARGS[$a1.start.Token,"ARGS"] $a1 $an*);
positional_argument: 
	attribute_argument_expression ;
named_argument_list: 
	a1=named_argument (',' an+=named_argument)* -> ^(ARGS[$a1.start.Token,"ARGS"] $a1 $an*);
named_argument: 
	identifier   '='   attribute_argument_expression ;
attribute_argument_expression: 
	expression ;

///////////////////////////////////////////////////////
//	Class Section
///////////////////////////////////////////////////////

class_declaration[CommonTree atts, CommonTree mods] returns [string name]
scope TypeContext;
:
	c='class' identifier  { $TypeContext::typeName = $identifier.text; } type_parameter_list? { $name = mkGenericTypeAlias($identifier.text, $type_parameter_list.names); }  class_base?   type_parameter_constraints_clauses?   class_body   ';'? 
    -> ^(CLASS[$c.Token] { dupTree($atts) } { dupTree($mods) } identifier type_parameter_constraints_clauses? type_parameter_list? class_base?  class_body );

type_parameter_list returns [List<string> names] 
@init {
    List<string> names = new List<string>();
}:
    '<'! attributes? t1=type_parameter { names.Add($t1.name); } ( ','!  attributes? tn=type_parameter { names.Add($tn.name); })* '>'! ;

type_parameter returns [string name]:
    identifier { $name = $identifier.text; } ;

class_base:
	// just put all types in a single list.  In NetMaker we will extract the base class if necessary
	':'   ts+=type (','   ts+=type)* -> ^(IMPLEMENTS $ts)*;
	
//interface_type_list:
//	ts+=type (','   ts+=type)* -> $ts+;

class_body:
	'{'   class_member_declarations?   '}' ;
class_member_declarations:
	class_member_declaration+ ;

///////////////////////////////////////////////////////
constant_declaration:
	'const'   type   constant_declarators   ';' ;
constant_declarators:
	constant_declarator (',' constant_declarator)* ;
constant_declarator:
	identifier   ('='   constant_expression)? ;
constant_expression:
	expression;

///////////////////////////////////////////////////////
field_declaration:
	variable_declarators   ';'!	;
variable_declarators:
	variable_declarator (','   variable_declarator)* ;
variable_declarator:
	type_name ('='   variable_initializer)? ;		// eg. event EventHandler IInterface.VariableName = Foo;

///////////////////////////////////////////////////////
method_declaration [CommonTree atts, CommonTree mods, List<string> modList, CommonTree type, string typeText]
@init {
    bool isToString = false;
    CommonTree exceptions = null;
    CommonTree optMain = null;
    bool isVoid = $typeText == "void";
    bool isInt = $typeText == "int"  || $typeText == "System.Int32" || $typeText == "Int32";
    bool isMain = isVoid || isInt;
    bool isMainHasArg = false;
}:
        // TODO:  According to the spec the C# Main() method should be static and not public.  We aren't checking for lack of public 
        // we can check the modifiers in modList if we want to enforce that.
		member_name { isToString = $member_name.text == "ToString"; isMain &= $member_name.text == "Main"; } 
        (type_parameter_list { isToString = false; isMain = false; })? 
        '(' 
            // We are looking for ToString(), and Main(string[] args), where arg is optional.  
            (formal_parameter_list 
              { isToString = false; 
                if (isMain) {
                    isMain = false;
                    // since we have an argument, must check its an array of String
                    if ($formal_parameter_list.tree != null && $formal_parameter_list.tree.Children != null && $formal_parameter_list.tree.Children.Count == 2) {
                        // parameter list children size is 2 (type arg)
                        CommonTree argTy = (CommonTree)$formal_parameter_list.tree.Children[0];
                        if (argTy != null && argTy.Children != null && argTy.Children.Count == 3) {
                            // Looking for Children of "String" "[" "]"
                            if (argTy.Children[0].Text.ToLower() == "string" &&
                                argTy.Children[1].Text == "[" &&
                                argTy.Children[2].Text == "]") {
                                // Bingo!
                                isMain = true;
                                isMainHasArg = true;
                            }
                        } 
                    }
                } 
              }
            )?   
        ')'  
        ( type_parameter_constraints_clauses { isToString = false; isMain = false; })?   
        b=method_body[isToString] 

        // build main method if required
        argParam=magicMainArgs[isMain && isMainHasArg, $member_name.tree.Token]
        mainApply=magicMainApply[isMain, $member_name.tree.Token, $TypeContext::typeName, $argParam.tree]
        mainCall=magicMainExit[isMain, isInt, $member_name.tree.Token, $mainApply.tree]
        mainMethod=magicMainWrapper[isMain, $member_name.tree.Token, $mainCall.tree]
    

        { if (isToString) {
              $member_name.tree.Token.Text = "toString";
          }
          exceptions = $b.exceptionList;
       }
       -> $mainMethod?
          ^(METHOD { dupTree($atts) } { dupTree($mods) } { dupTree($type) } 
            member_name type_parameter_constraints_clauses? type_parameter_list? formal_parameter_list? $b { exceptions });

method_body [bool smotherExceptions] returns [CommonTree exceptionList]:
	b=block nb=magicSmotherExceptions[ dupTree($b.tree) ] el=magicThrowsException[true,$b.tree.Token] { if (!smotherExceptions) $exceptionList=$el.tree; }
       -> {smotherExceptions}? $nb 
       -> $b
         ;
member_name returns [string rawId]:
    (type_or_generic '.')* i=identifier { $rawId = $i.text; }
   // keving [interface_type.identifier] | type_name '.' identifier 
    ;

member_name_orig returns [string name, List<string> tyargs]:
	qid { $name = $qid.name; $tyargs = $qid.tyargs; } ;		// IInterface<int>.Method logic added.

///////////////////////////////////////////////////////
property_declaration [CommonTree atts, CommonTree mods, CommonTree type]
scope { bool emptyGetterSetter; }
@init {
    $property_declaration::emptyGetterSetter = false;
    CommonTree privateVar = null;               
}
:
	i=member_name   '{'   ads=accessor_declarations[atts, mods, type, $i.text, $i.rawId]   '}' 
        v=magicMkPropertyVar[type, "__" + $i.tree.Text] { privateVar = $property_declaration::emptyGetterSetter ? $v.tree : null; }-> { privateVar } $ads ;

accessor_declarations [CommonTree atts, CommonTree mods, CommonTree type, string propName, string rawVarName]:
    accessor_declaration[atts, mods, type, propName, rawVarName]+;

accessor_declaration [CommonTree atts, CommonTree mods, CommonTree type, string propName, string rawVarName]
@init {
     CommonTree propBlock = null; 
     bool mkBody = false;
}:
	la=attributes? lm=accessor_modifier? 
      (g='get' ((';')=> gbe=';'  { $property_declaration::emptyGetterSetter = true; propBlock = $gbe.tree; mkBody = true; rawVarName = "__" + rawVarName; } 
                | gb=block { propBlock = $gb.tree; } ) getm=magicPropGetter[atts, $la.tree, mods, $lm.tree, type, $g.token, propBlock, propName, mkBody, rawVarName] -> $getm
       | s='set' ((';')=> sbe=';'  { $property_declaration::emptyGetterSetter = true; propBlock = $sbe.tree; mkBody = true; rawVarName = "__" + rawVarName; } 
                  | sb=block { propBlock = $sb.tree; } ) setm=magicPropSetter[atts, $la.tree, mods, $lm.tree, type, $s.token, propBlock, propName, mkBody, rawVarName] -> $setm)
    ;
accessor_modifier:
	'public' | 'protected' | 'private' | 'internal' ;

///////////////////////////////////////////////////////
event_declaration:
	'event'   type
		((member_name   '{') => member_name   '{'   event_accessor_declarations   '}'
		| variable_declarators   ';')	// typename=foo;
		;
event_modifiers:
	modifier+ ;
event_accessor_declarations:
	attributes?   ((add_accessor_declaration   attributes?   remove_accessor_declaration)
	              | (remove_accessor_declaration   attributes?   add_accessor_declaration)) ;
add_accessor_declaration:
	'add'   block ;
remove_accessor_declaration:
	'remove'   block ;

///////////////////////////////////////////////////////
//	enum declaration
///////////////////////////////////////////////////////
enum_declaration[CommonTree atts, CommonTree mods] returns [string name]
scope TypeContext;
:
	e='enum'   identifier  { $name = $identifier.text; $TypeContext::typeName = $identifier.text; } enum_base?   enum_body   ';'? 
            -> ^(ENUM[$e.token, "ENUM"] { dupTree($atts) } { dupTree($mods) } identifier enum_base? enum_body);
enum_base:
	':'   integral_type ;
enum_body:
	'{' (enum_member_declarations ','?)?   '}' -> ^(ENUM_BODY enum_member_declarations) ;
enum_member_declarations
@init {
    SortedList<int,CommonTree> members = new SortedList<int,CommonTree>();
    int next = 0;
}
@after{
    $enum_member_declarations.tree = (CommonTree)adaptor.Nil;
    int dummyCounter = 0;
    for (int i = 0; i < next; i++) {
        if (members.ContainsKey(i)) {
            adaptor.AddChild($enum_member_declarations.tree, members[i]);
        }
        else {
            adaptor.AddChild($enum_member_declarations.tree, adaptor.Create(IDENTIFIER, $e.start.Token, "__dummyEnum__" + dummyCounter++));
        }
    };
}
:
	e=enum_member_declaration[members,ref next] (',' enum_member_declaration[members, ref next])* 
    -> 
    ;
enum_member_declaration[ SortedList<int,CommonTree> members, ref int next]
@init {
    int calcValue = 0;
}:
        // Fill in members, a map from enum's value to AST
	attributes?   identifier  { $members[$next] = $identifier.tree; $next++; } 
        ((eq='='   ( ((NUMBER | Hex_number) (','|'}')) => 
                        { Console.Out.WriteLine($i); $members.Remove($next-1); } 
                           (i=NUMBER { calcValue = Int32.Parse($i.text); } 
                            | i=Hex_number { calcValue = Int32.Parse($i.text.Substring(2), NumberStyles.AllowHexSpecifier); } )  
                        { if (calcValue < 0 || calcValue > Int32.MaxValue) {
                             Warning($eq.line, "[UNSUPPORTED] enum member's value initialization ignored, only numeric literals in the range 0..MAXINT supported for enum values"); 
                             calcValue = $next-1;
                          }
                          else if (calcValue < $next-1) {
                             Warning($eq.line, "[UNSUPPORTED] enum member's value initialization ignored, value has already been assigned and enum values must be unique"); 
                             calcValue = $next-1;
                          }
                          $members[calcValue] = $identifier.tree; $next = calcValue + 1; } 
                  | expression  { Warning($eq.line, "[UNSUPPORTED] enum member's value initialization ignored, only numeric literals supported for enum values"); } ))?)! ;
//enum_modifiers:
//	enum_modifier+ ;
//enum_modifier:
//	'new' | 'public' | 'protected' | 'internal' | 'private' ;
integral_type: 
	'sbyte' | 'byte' | 'short' | 'ushort' | 'int' | 'uint' | 'long' | 'ulong' | 'char' ;

// B.2.12 Delegates
delegate_declaration[CommonTree atts, CommonTree mods] returns [string name]
scope TypeContext;
:
	d='delegate'   return_type   identifier { $name = $identifier.text; $TypeContext::typeName = $identifier.text; }  variant_generic_parameter_list?   
		'('   formal_parameter_list?   ')'   type_parameter_constraints_clauses?   ';' -> 
    ^(DELEGATE[$d.token, "DELEGATE"] { dupTree($atts) } { dupTree($mods) }  return_type   identifier type_parameter_constraints_clauses?  variant_generic_parameter_list?   
		'('   formal_parameter_list?   ')' );
delegate_modifiers:
	modifier+ ;
// 4.0
variant_generic_parameter_list returns [List<string> tyargs]
@init {
    $tyargs = new List<string>();
}:
	'<'!   variant_type_parameters[$tyargs]   '>'! ;
variant_type_parameters [List<string> tyargs]:
	v1=variant_type_variable_name { tyargs.Add($v1.text); } (',' vn=variant_type_variable_name  { tyargs.Add($vn.text); })* -> variant_type_variable_name+ ;
variant_type_variable_name:
	attributes?   variance_annotation?   type_variable_name ;
variance_annotation:
	'in' -> IN | 'out' -> OUT;

type_parameter_constraints_clauses:
	type_parameter_constraints_clause   (','   type_parameter_constraints_clause)* -> type_parameter_constraints_clause+ ;
type_parameter_constraints_clause:
	'where'   type_variable_name   ':'   type_parameter_constraint_list -> ^(TYPE_PARAM_CONSTRAINT type_variable_name type_parameter_constraint_list?) ;
// class, Circle, new()
type_parameter_constraint_list:                                                   
    ('class' | 'struct')   (','   secondary_constraint_list)?   (','   constructor_constraint)? -> secondary_constraint_list?
	| secondary_constraint_list   (','   constructor_constraint)? -> secondary_constraint_list
	| constructor_constraint -> ;
//primary_constraint:
//	class_type
//	| 'class'
//	| 'struct' ;
secondary_constraint_list:
	secondary_constraint (',' secondary_constraint)* -> secondary_constraint+ ;
secondary_constraint:
	type_name ;	// | type_variable_name) ;
type_variable_name: 
	identifier ;
// keving: TOTEST we drop new constraints,  but what will happen in Java for this case? 
constructor_constraint:
	'new'   '('   ')' ;
return_type:
	type
	|  void_type ;
formal_parameter_list:
	formal_parameter (',' formal_parameter)* -> ^(PARAMS formal_parameter+);
formal_parameter:
	attributes?   (fixed_parameter | parameter_array) 
	| '__arglist';	// __arglist is undocumented, see google
fixed_parameters:
	fixed_parameter   (','   fixed_parameter)* ;
// 4.0
fixed_parameter:
	parameter_modifier?   type   identifier   default_argument? ;
// 4.0
default_argument:
	'=' expression;
parameter_modifier:
	'ref' | 'out' | 'this' ;
parameter_array:
	p='params'^   t=type   identifier 
    { 
       // type will be an array, need to strip the final [] for java
       int numComponents = adaptor.GetChildCount($t.tree); 
       // sanity check
       if (numComponents >= 3 &&
            adaptor.GetType(adaptor.GetChild($t.tree, numComponents-2)) == OPEN_BRACKET &&
            adaptor.GetType(adaptor.GetChild($t.tree, numComponents-1)) == CLOSE_BRACKET) 
       {
           adaptor.DeleteChild($t.tree, numComponents-1);
           adaptor.DeleteChild($t.tree, numComponents-2);
       }
       else {
           Error($p.line, "[SOURCE ERROR] params type must be an array");
       }
    }
    ;

///////////////////////////////////////////////////////
interface_declaration[CommonTree atts, CommonTree mods] returns [string name]
scope TypeContext;
:
	c='interface'   identifier { $name = $identifier.text; $TypeContext::typeName = $identifier.text; }  variant_generic_parameter_list? 
    	interface_base?   type_parameter_constraints_clauses?   interface_body   ';'? 
    -> ^(INTERFACE[$c.Token] { dupTree($atts) } { dupTree($mods) } identifier type_parameter_constraints_clauses? variant_generic_parameter_list? interface_base?  interface_body );

interface_base:
	c=':'   ts+=type (','   ts+=type)* -> ^(EXTENDS[$c.token,"extends"] $ts)*;

interface_modifiers: 
	modifier+ ;
interface_body:
	'{'   interface_member_declarations?   '}' ;
interface_member_declarations:
	interface_member_declaration+ ;
interface_member_declaration:
	a=attributes?    m=modifiers?
		(vt=void_type   im1=interface_method_declaration[$a.tree, $m.tree, $vt.tree] -> $im1
		| ie=interface_event_declaration[$a.tree, $m.tree] -> $ie
		| t=type   ( (member_name   '(') => im2=interface_method_declaration[$a.tree, $m.tree, $t.tree] -> $im2
                   // property will rewrite to one, or two method headers
		         | (member_name   '{') => ip=interface_property_declaration[$a.tree, $m.tree, $t.tree] -> $ip //^(PROPERTY[$t.start.Token, "PROPERTY"] $a? $m? $t interface_property_declaration)
				 | ii=interface_indexer_declaration[$a.tree, $m.tree, $t.tree] -> $ii)
		) 
		;
interface_property_declaration [CommonTree atts, CommonTree mods, CommonTree type]:
	i=identifier   '{'   iads=interface_accessor_declarations[atts, mods, type, $i.text]   '}' -> $iads ;
interface_method_declaration [CommonTree atts, CommonTree mods, CommonTree type]:
	identifier   generic_argument_list?
	    '('   formal_parameter_list?   ')'   type_parameter_constraints_clauses?    s=';' magicThrowsException[true,$s.token]
       -> ^(METHOD { dupTree($atts) } { dupTree($mods) } { dupTree($type) } 
            identifier type_parameter_constraints_clauses? generic_argument_list? formal_parameter_list? magicThrowsException);
interface_event_declaration [CommonTree atts, CommonTree mods]:
	//attributes?   'new'?   
	'event'   type   identifier   ';' ; 
interface_indexer_declaration [CommonTree atts, CommonTree mods, CommonTree type]: 
	// attributes?    'new'?    type   
	'this'   '['   formal_parameter_list   ']'   '{'   indexer_accessor_declarations[atts,mods,type,$formal_parameter_list.tree]   '}' ;
interface_accessor_declarations [CommonTree atts, CommonTree mods, CommonTree type, string propName]:
    interface_accessor_declaration[atts, mods, type, propName]+
    ;
interface_accessor_declaration [CommonTree atts, CommonTree mods, CommonTree type, string propName]:
	la=attributes? (g='get' semi=';' magicPropGetter[atts, $la.tree, mods, null, type, $g.token, $semi.tree, propName, false, ""] -> magicPropGetter
                    | s='set' semi=';'  magicPropSetter[atts, $la.tree, mods, null, type, $s.token, $semi.tree, propName, false, ""] -> magicPropSetter)
    ;
	
///////////////////////////////////////////////////////
struct_declaration[CommonTree atts, CommonTree mods] returns [string name]
scope TypeContext;
:
	c='struct'  identifier  { $TypeContext::typeName = $identifier.text; } type_parameter_list? { $name = mkGenericTypeAlias($identifier.text, $type_parameter_list.names); }  class_base?   type_parameter_constraints_clauses?   struct_body[$identifier.text]   ';'? 
    -> ^(CLASS[$c.Token, "class"] { dupTree($atts) } { dupTree($mods) } identifier type_parameter_constraints_clauses? type_parameter_list? class_base? struct_body );

struct_body [string structName]:
	o='{'  magicDefaultConstructor[$o.token, structName] class_member_declarations? '}' ;


///////////////////////////////////////////////////////
indexer_declaration [CommonTree atts, CommonTree mods, CommonTree type]: 
	'this'   '['   formal_parameter_list   ']'   '{'   indexer_accessor_declarations[atts, mods, type, $formal_parameter_list.tree]   '}' ;
//indexer_declarator:
	//(type_name '.')?   
//	'this'   '['   formal_parameter_list   ']' ;
	

indexer_accessor_declarations [CommonTree atts, CommonTree mods, CommonTree type, CommonTree idxparams]:
    indexer_accessor_declaration[atts, mods, type, idxparams]+;

indexer_accessor_declaration [CommonTree atts, CommonTree mods, CommonTree type, CommonTree idxparams]
@init {
     CommonTree idxBlock = null; 
}:
	la=attributes? lm=accessor_modifier? 
      (g='get' ((';')=> gbe=';'  { idxBlock = $gbe.tree; } 
                | gb=block { idxBlock = $gb.tree; } ) geti=magicIdxGetter[atts, $la.tree, mods, $lm.tree, type, $g.token, idxBlock, idxparams] -> $geti
       | s='set' ((';')=> sbe=';'  { idxBlock = $sbe.tree; }
                  | sb=block { idxBlock = $sb.tree; } ) seti=magicIdxSetter[atts, $la.tree, mods, $lm.tree, type, $s.token, idxBlock, idxparams] -> $seti)
    ;

///////////////////////////////////////////////////////
operator_declaration:
	operator_declarator   operator_body ;
operator_declarator:
	'operator' 
	(('+' | '-')   '('   type   identifier   (binary_operator_declarator | unary_operator_declarator)
		| overloadable_unary_operator   '('   type identifier   unary_operator_declarator
		| overloadable_binary_operator   '('   type identifier   binary_operator_declarator) ;
unary_operator_declarator:
	   ')' ;
overloadable_unary_operator:
	/*'+' |  '-' | */ '!' |  '~' |  '++' |  '--' |  'true' |  'false' ;
binary_operator_declarator:
	','   type   identifier   ')' ;
// >> check needed
overloadable_binary_operator:
	/*'+' | '-' | */ '*' | '/' | '%' | '&' | '|' | '^' | '<<' | '>' '>' | '==' | '!=' | '>' | '<' | '>=' | '<=' ; 

conversion_operator_declaration:
	conversion_operator_declarator   operator_body ;
conversion_operator_declarator:
	('implicit' | 'explicit')  'operator'   type   '('   type   identifier   ')' ;
operator_body:
	block ;

///////////////////////////////////////////////////////
constructor_declaration[CommonTree atts, CommonTree mods, List<string> modList]:
		i=identifier   '('   p=formal_parameter_list?   s=')'   init=constructor_initializer? b=constructor_body[$init.tree] sb=magicSmotherExceptionsThrow[$b.tree, "ExceptionInInitializerError"] magicThrowsException[true,$s.token]
            -> {modList.Contains("static")}? ^(STATIC_CONSTRUCTOR[$i.tree.Token, "CONSTRUCTOR"] { dupTree($atts) } { dupTree($mods) } $sb)
            ->  ^(CONSTRUCTOR[$i.tree.Token, "CONSTRUCTOR"] { dupTree($atts) } { dupTree($mods) } $i $p? $b magicThrowsException);
constructor_initializer: 
	':' tok='this' '('   argument_list?   ')' 
         -> ^(APPLY[$tok.token, "APPLY"] $tok argument_list?) SEMI[$tok.token, ";"]
	| ':' tok='base' '('   argument_list?   ')' 
         -> ^(APPLY[$tok.token, "APPLY"] SUPER[$tok.token, "super"] argument_list?) SEMI[$tok.token, ";"] 
    ;
constructor_body[CommonTree init]:
	{init == null}?=> s=';' -> $s 
	| s1=';' -> OPEN_BRACE[$s1.token, "{"] { dupTree(init) } CLOSE_BRACE[$s1.token, "}"]
    | a='{' ss+=statement* b='}' -> $a { dupTree(init) } $ss* $b
    ;

///////////////////////////////////////////////////////
//static_constructor_declaration:
//	identifier   '('   ')'  static_constructor_body ;
//static_constructor_body:
//	block ;

///////////////////////////////////////////////////////
destructor_declaration:
	t='~'  identifier   '('   ')'    destructor_body f=magicFinalize[$t.token, $destructor_body.tree] -> $f;
destructor_body:
	block ;

///////////////////////////////////////////////////////
invocation_expression:
	invocation_start   (((arguments[null]   ('['|'.'|'->')) => arguments[ (CommonTree)adaptor.Create(KGHOLE, "KGHOLE") ]   invocation_part)
						| invocation_part)*   arguments[ (CommonTree)adaptor.Create(KGHOLE, "KGHOLE") ] ;
invocation_start:
	predefined_type 
	| (identifier    generic_argument_list)	=> identifier   generic_argument_list
	| 'this' 
	| b='base' -> SUPER[$b.token, "super"]
	| identifier   ('::'   identifier)?
	| typeof_expression             // typeof(Foo).Name
	;
invocation_part:
	 access_identifier[ (CommonTree)adaptor.Create(KGHOLE, "KGHOLE") ]
	| brackets[ (CommonTree)adaptor.Create(KGHOLE, "KGHOLE") ] ;

///////////////////////////////////////////////////////

statement:
	(declaration_statement) => declaration_statement
	| (identifier   ':') => labeled_statement
	| embedded_statement 
	;
embedded_statement:
	block
	| selection_statement	// if, switch
	| iteration_statement	// while, do, for, foreach
	| jump_statement		// break, continue, goto, return, throw
	| try_statement
	| checked_statement
	| unchecked_statement
	| lock_statement
	| using_statement 
	| yield_statement 
	| unsafe_statement
	| fixed_statement
	| expression_statement	// expression!
	;
fixed_statement:
	'fixed'   '('   pointer_type fixed_pointer_declarators   ')'   embedded_statement ;
fixed_pointer_declarators:
	fixed_pointer_declarator   (','   fixed_pointer_declarator)* ;
fixed_pointer_declarator:
	identifier   '='   fixed_pointer_initializer ;
fixed_pointer_initializer:
	//'&'   variable_reference   // unary_expression covers this
	expression;
unsafe_statement:
	'unsafe'^   block;
labeled_statement:
	identifier   ':'^   statement ;
declaration_statement:
	(local_variable_declaration 
	| local_constant_declaration) ';' ;
local_variable_declaration returns [List<string> variableNames]:
	local_variable_type   local_variable_declarators { $variableNames = $local_variable_declarators.variableNames; };
local_variable_type:
	('var') => 'var'
	| ('dynamic') => 'dynamic'
	| type ;
local_variable_declarators returns [List<string> variableNames]
@init {
    $variableNames = new List<string>(); 
}:
	i1=local_variable_declarator { $variableNames.Add($i1.variableName); } (',' ip=local_variable_declarator { $variableNames.Add($ip.variableName); })* ;
local_variable_declarator returns [string variableName]:
	identifier { $variableName = $identifier.text; } ('='   local_variable_initializer)? ; 
local_variable_initializer:
	expression
	| array_initializer 
	| stackalloc_initializer;
stackalloc_initializer:
	'stackalloc'   unmanaged_type   '['   expression   ']' ;
local_constant_declaration:
	'const'   type   constant_declarators ;
expression_statement:
	expression   ';' ;

// TODO: should be assignment, call, increment, decrement, and new object expressions
statement_expression:
	expression
	;
selection_statement:
	if_statement
	| switch_statement ;
if_statement:
	// else goes with closest if
	i='if'   '('   boolean_expression   ')'   embedded_statement (('else') => else_statement)? -> ^(IF[$i.Token] boolean_expression SEP embedded_statement else_statement?)
//	'if'   '('   boolean_expression   ')'   embedded_statement (('else') => else_statement)?
	;
else_statement:
	'else'   embedded_statement	;
switch_statement:
	s='switch'   '('   expression   ')'   switch_block -> ^($s expression switch_block);
switch_block:
	'{'!   switch_section*   '}'! ;
//switch_sections:
//	switch_section+ ;
switch_section:
	switch_label+   statement_list -> ^(SWITCH_SECTION switch_label+ statement_list);
//switch_labels:
//	switch_label+ ;
switch_label:
	('case'^   constant_expression   ':'!)
	| ('default'   ':'!);
iteration_statement:
	while_statement
	| do_statement
	| for_statement
	| foreach_statement ;
while_statement:
	w='while'   '('   boolean_expression   ')'   embedded_statement -> ^($w boolean_expression SEP embedded_statement);
do_statement:
	'do'   embedded_statement   'while'   '('   boolean_expression   ')'   ';' ;
for_statement:
	f='for'   '('   for_initializer?   ';'   for_condition?   ';'   for_iterator?   ')'   embedded_statement 
         -> ^($f for_initializer? SEP for_condition? SEP for_iterator? SEP embedded_statement);
for_initializer:
	(local_variable_declaration) => local_variable_declaration
	| statement_expression_list 
	;
for_condition:
	boolean_expression ;
for_iterator:
	statement_expression_list ;
statement_expression_list:
	statement_expression (',' statement_expression)* ;
foreach_statement:
	f='foreach'   '('   local_variable_type   identifier   'in'   expression   ')'   embedded_statement 
    -> ^($f local_variable_type   identifier  expression SEP  embedded_statement);
jump_statement:
	break_statement
	| continue_statement
	| goto_statement
	| return_statement
	| throw_statement ;
break_statement:
	'break'   ';' ;
continue_statement:
	'continue'   ';' ;
goto_statement:
	'goto'   ( identifier
			 | 'case'   constant_expression
			 | 'default')   ';' ;
return_statement:
	'return'^   expression?   ';'! ;
throw_statement
// If throw exp is missing then it is the var from closest enclosing catch
@init {
    CommonTree var = null;
    bool missingThrowExp = true;
}:
	t='throw'   (e=expression { missingThrowExp = false;})?  { var = missingThrowExp ? dupTree($catch_clause::throwVar) : $e.tree; } ';' -> ^($t { var });
try_statement:
      t='try'   block   ( catch_clauses   finally_clause?
					  | finally_clause) -> ^($t block catch_clauses? finally_clause?);
// We rewrite the catch clauses so that they all have the form "(catch Type Var)" by introducing
// Throwable and dummy vars as necessary
catch_clauses:
    catch_clause+;
catch_clause
scope { CommonTree throwVar; }
@init {
    CommonTree ty = null, var = null;
}:
    c='catch' ('('   given_t=class_type { ty = $given_t.tree; }  (given_v=identifier { var = $given_v.tree; } | magic_v=magicCatchVar { var = $magic_v.tree; } ) ')'
                 | magic_t=magicThrowableType[true,$c.token] magic_v=magicCatchVar { ty = $magic_t.tree; var = $magic_v.tree; })   { $catch_clause::throwVar = var; } block
       -> ^($c { ty } { var } block)
    ;
finally_clause:
	'finally'^   block ;
checked_statement:
	'checked'   block ;
unchecked_statement:
	'unchecked'   block ;
lock_statement:
	'lock'   '('  expression   ')'   embedded_statement ;
using_statement
@init {
    CommonTree disposers = null;
}:
// see http://msdn.microsoft.com/en-us/library/yh598w02.aspx for translation
	u='using'   '('    resource_acquisition   c=')'    embedded_statement
     { disposers = addDisposeVars($c.token, $resource_acquisition.resourceNames); } 
     f=magicFinally[$c.token, disposers]
     magicTry[$u.token, $embedded_statement.tree, null, $f.tree] 
     -> OPEN_BRACE[$u.token, "{"] 
            resource_acquisition SEMI[$c.token, ";"] 
            magicTry
        CLOSE_BRACE[$u.token, "}"] 
     ;
resource_acquisition returns [List<string> resourceNames]
@init {
    $resourceNames = new List<string>();
}:
	(local_variable_declaration) => local_variable_declaration { $resourceNames = $local_variable_declaration.variableNames; } 
	| expression { $resourceNames.Add("__newVar"+newVarCtr); } -> ^(TYPE[$expression.tree.Token, "TYPE"] IDENTIFIER[$expression.tree.Token, "IDisposable"]) 
                         IDENTIFIER[$expression.tree.Token, "__newVar"+newVarCtr++] ASSIGN[$expression.tree.Token, "="] expression //SEMI[$expression.tree.Token, ";"]
    ;
yield_statement:
	'yield'   ('return'   expression   ';'
	          | 'break'   ';') ;

///////////////////////////////////////////////////////
//	Lexar Section
///////////////////////////////////////////////////////

predefined_type returns [string thetext]
@after{
    string newText;
    if (predefined_type_map.TryGetValue($predefined_type.tree.Token.Text, out newText)) {
        $predefined_type.tree.Token.Text = newText;
    }
}:
	  'bool'    { $thetext = "System.Boolean"; }
    | 'byte'    { $thetext = "System.Byte"; }    
    | 'char'    { $thetext = "System.Char"; } 
    | 'decimal' { $thetext = "System.Decimal"; } 
    | 'double'  { $thetext = "System.Double"; } 
    | 'float'   { $thetext = "System.Single"; } 
    | 'int'     { $thetext = "System.Int32"; }   
    | 'long'    { $thetext = "System.Int64"; } 
    | 'object'  { $thetext = "System.Object"; } 
    | 'sbyte'   { $thetext = "System.SByte"; } 
	| 'short'   { $thetext = "System.Int16"; } 
    | 'string'  { $thetext = "System.String"; } 
    | 'uint'    { $thetext = "System.UInt32"; } 
    | 'ulong'   { $thetext = "System.UInt64"; } 
    | 'ushort'  { $thetext = "System.UInt16"; } 
    ;

identifier
@after {
    string fixedId = fixBrokenId($identifier.tree.Token.Text); 
    $identifier.tree.Token.Text = fixedId;
}:
 	IDENTIFIER | also_keyword; 

keyword:
	'abstract' | 'as' | 'base' | 'bool' | 'break' | 'byte' | 'case' |  'catch' | 'char' | 'checked' | 'class' | 'const' | 'continue' | 'decimal' | 'default' | 'delegate' | 'do' |	'double' | 'else' |	 'enum'  | 'event' | 'explicit' | 'extern' | 'false' | 'finally' | 'fixed' | 'float' | 'for' | 'foreach' | 'goto' | 'if' | 'implicit' | 'in' | 'int' | 'interface' | 'internal' | 'is' | 'lock' | 'long' | 'namespace' | 'new' | 'null' | 'object' | 'operator' | 'out' | 'override' | 'params' | 'private' | 'protected' | 'public' | 'readonly' | 'ref' | 'return' | 'sbyte' | 'sealed' | 'short' | 'sizeof' | 'stackalloc' | 'static' | 'string' | 'struct' | 'switch' | 'this' | 'throw' | 'true' | 'try' | 'typeof' | 'uint' | 'ulong' | 'unchecked' | 'unsafe' | 'ushort' | 'using' | 'virtual' | 'void' | 'volatile' ;

also_keyword:
	'add' | 'alias' | 'assembly' | 'module' | 'field' | 'method' | 'param' | 'property' | 'type' | 'yield'
	| 'from' | 'into' | 'join' | 'on' | 'where' | 'orderby' | 'group' | 'by' | 'ascending' | 'descending' 
	| 'equals' | 'select' | 'pragma' | 'let' | 'remove' | 'get' | 'set' | 'var' | '__arglist' | 'dynamic' | 'elif' 
	| 'endif' | 'define' | 'undef';

literal:
	Real_literal
	| n=NUMBER -> {UInt64.Parse($n.text) > Int32.MaxValue}? LONGNUMBER[$n.token, $n.text]
               -> $n
	| Hex_number
	| Character_literal
	| STRINGLITERAL
	| Verbatim_string_literal
	| TRUE
	| FALSE
	| NULL 
	;

void_type:
    v='void' -> ^(TYPE[$v.token, "TYPE"] $v);

magicThrowableType[bool isOn, IToken tok]:
 -> {isOn}? ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, Cfg.TranslatorExceptionIsThrowable ? "Throwable" : "Exception"])
 -> 
;

magicCatchVar:
  -> IDENTIFIER["__dummyCatchVar" + dummyCatchVarCtr++];

magicPropGetter[CommonTree atts, CommonTree localatts, CommonTree mods, CommonTree localmods, CommonTree type, IToken getTok, CommonTree body, string propName, bool mkBody, string varName]
@init {
    CommonTree realBody = body;
    CommonTree exceptionList = null;
}: 
    ( { mkBody }? => b=magicGetterBody[getTok,varName] { realBody = $b.tree; } | e=magicThrowsException[true,getTok] { exceptionList = $e.tree; })
    -> ^(METHOD[$type.token, "METHOD"] { dupTree(mods) } { dupTree(type)} IDENTIFIER[getTok, "get"+propName] { dupTree(realBody) } { exceptionList }) 
    ;
magicPropSetter[CommonTree atts, CommonTree localatts, CommonTree mods, CommonTree localmods, CommonTree type, IToken setTok, CommonTree body, string propName, bool mkBody, string varName]
@init {
    CommonTree realBody = body;
    CommonTree exceptionList = null;
}: 
    ( { mkBody }? => b=magicSetterBody[setTok,varName] { realBody = $b.tree; }| e=magicThrowsException[true,setTok] { exceptionList = $e.tree; } )
    -> ^(METHOD[$type.token, "METHOD"] { dupTree(mods) } ^(TYPE[setTok, "TYPE"] IDENTIFIER[setTok, "void"] ) IDENTIFIER[setTok, "set"+propName] ^(PARAMS[setTok, "PARAMS"] { dupTree(type)} IDENTIFIER[setTok, "value"]) { dupTree(realBody) } { exceptionList } ) 
    ;

magicSemi:
   -> SEMI;

magicMkPropertyVar[CommonTree type, string varText] :
 -> ^(FIELD[$type.token, "FIELD"] PRIVATE[$type.token, "private"] { dupTree(type) } IDENTIFIER[$type.token, varText])
    ; 

magicGetterBody[IToken getTok, string varName]:    
 -> OPEN_BRACE[getTok,"{"] ^(RETURN[getTok, "return"] IDENTIFIER[getTok, varName]) CLOSE_BRACE[getTok,"}"];
magicSetterBody[IToken setTok, string varName]:    
 -> OPEN_BRACE[setTok,"{"] IDENTIFIER[setTok, varName] ASSIGN[setTok,"="] IDENTIFIER[setTok, "value"] SEMI[setTok, ";"] CLOSE_BRACE[setTok,"}"] ;

magicIdxGetter[CommonTree atts, CommonTree localatts, CommonTree mods, CommonTree localmods, CommonTree type, IToken getTok, CommonTree body, CommonTree idxparams]
: 
    magicThrowsException[true,getTok]
    -> ^(METHOD[$type.token, "METHOD"] { dupTree(mods) } { dupTree(type)} IDENTIFIER[getTok, "get___idx"] { dupTree(idxparams) } { dupTree(body) } magicThrowsException) 
    ;
magicIdxSetter[CommonTree atts, CommonTree localatts, CommonTree mods, CommonTree localmods, CommonTree type, IToken setTok, CommonTree body, CommonTree idxparams]
@init {
    CommonTree augParams = dupTree(idxparams);
    adaptor.AddChild(augParams, dupTree($type));
    adaptor.AddChild(augParams, (CommonTree)adaptor.Create(IDENTIFIER, setTok, "value"));
}
:
    magicThrowsException[true,setTok] 
    -> ^(METHOD[$type.token, "METHOD"] { dupTree(mods) } ^(TYPE[setTok, "TYPE"] IDENTIFIER[setTok, "void"] ) IDENTIFIER[setTok, "set___idx"] { augParams } { dupTree(body) } magicThrowsException ) 
    ;

// keving: can't get this to work reasonably
//magicMkConstModifiers[IToken tok, List<string> filter]: 
//    ({ !filter.Contains("static") }?=> -> STATIC[tok, "static"] ) ( { !filter.Contains("public") }?=> -> $magicMkConstModifiers FINAL[tok, "final"] ); 


magicSmotherExceptions[CommonTree body]:
  magicSmotherExceptionsThrow[body, "RuntimeException"] 
;

magicSmotherExceptionsThrow[CommonTree body, string exception]:
  v=magicCatchVar magicThrowableType[true, body.Token]
 -> OPEN_BRACE["{"]
       ^(TRY["try"] 
            { dupTree(body) }
         ^(CATCH["catch"] magicThrowableType { dupTree($v.tree) } 
           OPEN_BRACE["{"] ^(THROW["throw"] ^(NEW["new"] ^(TYPE["TYPE"] IDENTIFIER[exception]) ^(ARGS["ARGS"] { dupTree($v.tree) }))) CLOSE_BRACE["}"]))
    CLOSE_BRACE["}"]
;

// METHOD{ public static TYPE{ void } main PARAMS{ TYPE{ String [ ] } args } { APPLY{ .{ System exit } ARGS{ APPLY{ .{ Program Main } } } } ;

magicMainArgs[bool isOn, IToken tok]:
 -> { isOn }?
      ^(ARGS[tok, "ARGS"] IDENTIFIER[tok, "args"])
 -> 
;

magicMainApply[bool isOn, IToken tok, string klass, CommonTree args]:
 -> { isOn }?
     ^(APPLY[tok, "APPLY"] ^(DOT[tok,"."] IDENTIFIER[tok,klass] IDENTIFIER[tok,"Main"]) { dupTree(args) } ) 
 -> 
; 

magicMainExit[bool isOn, bool retInt, IToken tok, CommonTree body]:
 -> { isOn && retInt }?
     ^(APPLY[tok, "APPLY"] ^(DOT[tok,"."] IDENTIFIER[tok,"System"] IDENTIFIER[tok,"exit"]) ^(ARGS[tok, "ARGS"] { dupTree(body) } ) ) 
 -> { isOn }?
      { dupTree(body) }
 -> 
;
    

magicMainWrapper[bool isOn, IToken tok, CommonTree body]:
 magicThrowsException[isOn,tok]
 -> { isOn }?
    ^(METHOD[tok, "METHOD"]
         PUBLIC[tok, "public"] STATIC[tok,"static"] 
         ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "void"]) 
             IDENTIFIER[tok, "main"] ^(PARAMS[tok, "PARAMS"] ^(TYPE[tok, "TYPE"] IDENTIFIER[tok,"String"] OPEN_BRACKET[tok, "["] CLOSE_BRACKET[tok, "]"]) IDENTIFIER[tok, "args"]) 
              OPEN_BRACE[tok, "{"] { dupTree(body) } SEMI[tok, ";"] CLOSE_BRACE[tok, "}"] 
      magicThrowsException)
 -> 
;

magicTry[IToken tok, CommonTree body, CommonTree catches, CommonTree fin]:
->
   ^(TRY[tok, "try"] { dupTree(body) } { dupTree(catches) } { dupTree(fin) })
;

magicDispose[IToken tok, string var]:
-> ^(IF[tok, "if"] ^(NOT_EQUAL[tok, "!="] IDENTIFIER[tok, var] NULL[tok, "null"]) SEP 
         ^(APPLY[tok, "APPLY"] ^(DOT[tok, "."] ^(CAST_EXPR[tok, "CAST"] ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "IDisposable"]) IDENTIFIER[tok, var]) IDENTIFIER[tok, "Dispose"])) SEMI[tok, ";"])
;

magicFinally[IToken tok, CommonTree statement_list]:
->
   ^(FINALLY[tok, "finally"] OPEN_BRACE[tok, "{"] { dupTree(statement_list) } CLOSE_BRACE[tok, "}"])
;

magicFinalize[IToken tok, CommonTree body]:
 magicThrowsException[true,tok]
->
    ^(METHOD[tok, "METHOD"]
         PROTECTED[tok, "protected"] 
         ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "void"]) IDENTIFIER[tok, "finalize"] 
              OPEN_BRACE[tok, "{"] 
                    ^(TRY[tok, "try"] { dupTree(body) } 
                         ^(FINALLY[tok, "finally"] OPEN_BRACE[tok, "{"] ^(APPLY[tok, "APPLY"] ^(DOT[tok,"."] SUPER[tok,"super"] IDENTIFIER[tok,"finalize"])) SEMI[tok, ";"] CLOSE_BRACE[tok, "}"]))
              CLOSE_BRACE[tok, "}"]
     // Always throws Throwable to match Object.finalize()
     EXCEPTION[tok, "Throwable"])
;

magicDefaultConstructor[IToken tok, string name]:
->
    ^(CONSTRUCTOR[tok, "CONSTRUCTOR"]
         PUBLIC[tok, "public"] 
         IDENTIFIER[tok, name]
              OPEN_BRACE[tok, "{"] 
              CLOSE_BRACE[tok, "}"] 
      )
;

magicThrowsException[bool isOn, IToken tok]:
->  {isOn}? EXCEPTION[tok, Cfg.TranslatorExceptionIsThrowable ? "Throwable" : "Exception"]
-> 
;

