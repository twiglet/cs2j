// csCrawl.g
//
// CSharp AST Crawler
//
// Kevin Glynn
// kevin.glynn@twigletsoftware.com
// June 2010
  
tree grammar csCrawl;

options {
    tokenVocab=cs;
    ASTLabelType=CommonTree;
	language=CSharp2;
	backtrack=true;
}

@namespace { RusticiSoftware.Translator.CSharp }

@header
{
	using System.Text;
}

/********************************************************************************************
                          Parser section
*********************************************************************************************/

///////////////////////////////////////////////////////
compilation_unit2: 
	{ Console.Out.WriteLine("Debug: start"); } using_directives2
	;

using_directives2:
    ^(USING_DIRECTIVE 'using' { Console.Out.WriteLine("Debug: using"); } namespace_name2 ';') 
	;

namespace_name2:
    ^(NAMESPACE_OR_TYPE_NAME namespace_component2) 
	;
	
namespace_component2:
    ^(NSTN identifier2)
	;

identifier2:
    ^(ID id=IDENTIFIER { Console.Out.WriteLine("Identifier: " + id.Text);})
	;

compilation_unit:
//	extern_alias_directives?   
	using_directives?  	
//	global_attributes?   
	namespace_body?		// specific namespace or in the global namespace
	;
namespace_declaration:
	^(NAMESPACE_DECL 'namespace' qualified_identifier  namespace_block   ';'?) ;
namespace_block:
	'{'   namespace_body   '}' ;
namespace_body:
	extern_alias_directives?   using_directives?   namespace_member_declarations? ;
extern_alias_directives:
	extern_alias_directive+ ;
extern_alias_directive:
	'extern'   'alias'   identifier  ';' ;
using_directives:
	using_directive+ ;
using_directive:
	^(USING_DIRECTIVE using_alias_directive? using_namespace_directive?);
using_alias_directive:
	'using'	  identifier   '='   namespace_or_type_name   ';' ;
using_namespace_directive:
	'using'   namespace_name   ';' ;
namespace_member_declarations:
	namespace_member_declaration+ ;
namespace_member_declaration:
	namespace_declaration
	/*| type_declaration */;
//type_declaration:
//	class_declaration
//	| struct_declaration
//	| interface_declaration
//	| enum_declaration
//	| delegate_declaration ;
qualified_alias_member:
	identifier   '::'   identifier   generic_argument_list? ;

// Identifiers
qualified_identifier:
	identifier ('.' identifier)* ;

qid:		// qualified_identifier v2
	qid_start qid_part* ;
qid_start:
	identifier ('::' identifier)? generic_argument_list?
	| 'this'
	| 'base'
	| predefined_type
	| literal ;		// 0.ToString() is legal
qid_part:
	^(QID_PART access_operator   identifier    generic_argument_list?) ;


// B.2.1 Basic Concepts
namespace_name
	: namespace_or_type_name ;
type_name: 
	^(TYPE_NAME namespace_or_type_name) ;
namespace_or_type_name:
	^(NAMESPACE_OR_TYPE_NAME 
	     ^(NSTN identifier  generic_argument_list?)
     ) ;   
	//	 ^(NSTN   '::'   identifier   generic_argument_list?)?   
	//	 ^(NSTN   identifier  generic_argument_list?)*
	//  ) ;
//	| qualified_alias_member (the :: part)
    //;
 
type:
	^(TYPE type_name? predefined_type? rank_specifiers '*'*)
	| ^(TYPE type_name '*'+)
	| ^(TYPE type_name '?')
	| ^(TYPE type_name)
	| ^(TYPE predefined_type '*'+)
	| ^(TYPE predefined_type '?')
	| ^(TYPE predefined_type)
	| ^(TYPE 'void' '*'+) ;

rank_specifiers: 
	rank_specifier+ ;        
rank_specifier: 
	'['   dim_separators?   ']' ;
dim_separators: 
	','+ ;
type_list:
	type (',' type)* ;
  
type_arguments: 
	type_argument+
	;
type_argument: 
	type ;
type_variable_name: 
	identifier ;
	 
generic_argument_list: 
	'<'   type_arguments   '>' ;

access_operator:
	'.'  |  '->' ;

predefined_type:
	  ^(PREDEFINED_TYPE 'bool'   )
	| ^(PREDEFINED_TYPE 'byte'   )
	| ^(PREDEFINED_TYPE 'char'   )
	| ^(PREDEFINED_TYPE 'decimal') 
	| ^(PREDEFINED_TYPE 'double' )
	| ^(PREDEFINED_TYPE 'float'  )
	| ^(PREDEFINED_TYPE 'int'    )
	| ^(PREDEFINED_TYPE 'long'   )
	| ^(PREDEFINED_TYPE 'object' )
	| ^(PREDEFINED_TYPE 'sbyte'  )
	| ^(PREDEFINED_TYPE 'short'  )
	| ^(PREDEFINED_TYPE 'string' )
	| ^(PREDEFINED_TYPE 'uint'   )
	| ^(PREDEFINED_TYPE 'ulong'  )
	| ^(PREDEFINED_TYPE 'ushort' );

identifier:
	^(ID id=IDENTIFIER { Console.Out.WriteLine("Identifier: " + id.Text);})
	| ^(ID also_keyword);  
	
literal:
	Real_literal
	| NUMBER
	| Hex_number
	| Character_literal
	| STRINGLITERAL
	| Verbatim_string_literal
	| TRUE
	| FALSE
	| NULL 
	;

keyword:
	'abstract' | 'as' | 'base' | 'bool' | 'break' | 'byte' | 'case' |  'catch' | 'char' | 'checked' | 'class' | 'const' | 'continue' | 'decimal' | 'default' | 'delegate' | 'do' |	'double' | 'else' |	 'enum'  | 'event' | 'explicit' | 'extern' | 'false' | 'finally' | 'fixed' | 'float' | 'for' | 'foreach' | 'goto' | 'if' | 'implicit' | 'in' | 'int' | 'interface' | 'internal' | 'is' | 'lock' | 'long' | 'namespace' | 'new' | 'null' | 'object' | 'operator' | 'out' | 'override' | 'params' | 'private' | 'protected' | 'public' | 'readonly' | 'ref' | 'return' | 'sbyte' | 'sealed' | 'short' | 'sizeof' | 'stackalloc' | 'static' | 'string' | 'struct' | 'switch' | 'this' | 'throw' | 'true' | 'try' | 'typeof' | 'uint' | 'ulong' | 'unchecked' | 'unsafe' | 'ushort' | 'using' |	 'virtual' | 'void' | 'volatile' ;

also_keyword:
	'add' | 'alias' | 'assembly' | 'module' | 'field' | 'event' | 'method' | 'param' | 'property' | 'type' 
	| 'yield' | 'from' | 'into' | 'join' | 'on' | 'where' | 'orderby' | 'group' | 'by' | 'ascending'
	| 'descending' | 'equals' | 'select' | 'pragma' | 'let' | 'remove' | 'set' | 'var' | '__arglist' | 'dynamic';
     