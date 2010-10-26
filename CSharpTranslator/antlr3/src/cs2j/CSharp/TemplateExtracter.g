// SignatureExtracter.g
//
// Crawler that extracts the signatures (typereptemplates) from a CSharp AST 
//
// Kevin Glynn
// kevin.glynn@twigletsoftware.com
// June 2010
  
tree grammar TemplateExtracter;

options {
    tokenVocab=cs;
    ASTLabelType=CommonTree;
    language=CSharp2;
    superClass='RusticiSoftware.Translator.CSharp.CommonWalker';
    //backtrack=true;
}

scope UseScope {
    IList<String> usePath;
}

@namespace { RusticiSoftware.Translator.CSharp }

@header
{
	using System.Text;
	using RusticiSoftware.Translator.CLR;
}

@members 
{

    // This is a global 'magic' string used to return strings from within complex productions.
    // For example a namespace rule will set the string that represents the namespace, saves
    // passing a whole load of returns through intermediate rules.
    protected string Capture {get; set;}

}

/********************************************************************************************
                          Parser section
*********************************************************************************************/

///////////////////////////////////////////////////////

compilation_unit[CS2JSettings inCfg]
scope UseScope;
@init {
    Cfg = inCfg;
    $UseScope::usePath = new List<String>();
}
:
{ Debug("start template extraction"); }    
	namespace_body
{ Debug("end template extraction"); }    
	;

namespace_declaration:
	'namespace'   qualified_identifier   namespace_block   ';'? ;
namespace_block:
	'{'   namespace_body   '}' ;
namespace_body:
	extern_alias_directives?   using_directives?   global_attributes?   namespace_member_declarations? ;
extern_alias_directives:
	extern_alias_directive+ ;
extern_alias_directive:
	'extern'   'alias'   identifier  ';' ;
using_directives:
	using_directive+ ;
using_directive:
	(using_alias_directive
	| using_namespace_directive) ;
using_alias_directive:
	'using'	  identifier   '='   namespace_or_type_name   ';' ;
using_namespace_directive:
	'using'   namespace_name   ';' ;
namespace_member_declarations:
	namespace_member_declaration+ ;
namespace_member_declaration:
	namespace_declaration
	| attributes?   modifiers?   type_declaration ;
type_declaration:
	('partial') => 'partial'   (class_declaration
								| struct_declaration
								| interface_declaration)
	| class_declaration
	| struct_declaration
	| interface_declaration
	| enum_declaration
	| delegate_declaration ;
	
	
// ad-hoc

///////////////////////////////////////////////////////
//	Type Section
///////////////////////////////////////////////////////

class_declaration
	:	 'class' identifier ';' ;
struct_declaration
	:	 'struct' identifier ';' ;
interface_declaration
	:	 'interface' identifier ';' ;
enum_declaration
	:	 'enum' identifier ';' ;
delegate_declaration
	:	 'delegate' identifier ';' ;

type_name: 
	namespace_or_type_name ;
namespace_or_type_name:
	 type_or_generic   ('::' type_or_generic)? ('.'   type_or_generic)* ;
type_or_generic:
	(identifier   '<') => identifier   generic_argument_list
	| identifier 	
;

generic_argument_list: 
	'<'   type_arguments   '>' ;
type_arguments: 
	type (',' type)* ;

type:
	  ((predefined_type | type_name)  rank_specifiers) => (predefined_type | type_name)   rank_specifiers   '*'*
	| ((predefined_type | type_name)  ('*'+ | '?')) => (predefined_type | type_name)   ('*'+ | '?')
	| (predefined_type | type_name)
	| 'void' '*'+
	;

qualified_identifier:
	identifier ('.' identifier)* ;

namespace_name
	: namespace_or_type_name ;
modifiers:
	modifier+ ;
modifier: 
	'new' | 'public' | 'protected' | 'private' | 'internal' | 'unsafe' | 'abstract' | 'sealed' | 'static'
	| 'readonly' | 'volatile' | 'extern' | 'virtual' | 'override';

rank_specifiers: 
	rank_specifier+ ;        
rank_specifier: 
	'['   dim_separators?   ']' ;
dim_separators: 
	','+ ;
	
global_attributes: 
	global_attribute+ ;
global_attribute: 
	'[' 'fred'   ','?   ']' ;
attributes: 
	attribute_sections ;
attribute_sections: 
	attribute_section+ ;
attribute_section: 
	'['  'jim'    ','?   ']' ;

predefined_type:
	  'bool' | 'byte'   | 'char'   | 'decimal' | 'double' | 'float'  | 'int'    | 'long'   | 'object' | 'sbyte'  
	| 'short'  | 'string' | 'uint'   | 'ulong'  | 'ushort' ;
	
identifier:
 	IDENTIFIER { Debug($IDENTIFIER.Text); } ; 

