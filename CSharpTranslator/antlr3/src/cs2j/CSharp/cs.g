grammar cs;

options {
    memoize=true;
	output=AST;
    language=CSharp2;
}

tokens {
            PACKAGE;
            CLASS;
            EXTENDS;
            IMPLEMENTS;
            IMPORT;
            INTERFACE;
            FINAL; /* final modifier */
            IN;
            OUT;
            CONST;
            EVENT;
            METHOD;
            PROPERTY;
            INDEXER;
            FIELD;
            OPERATOR;
            ENUM;
            DELEGATE;
            CONVERSION_OPERATOR;
            CONSTRUCTOR;
            DESTRUCTOR;
            METHOD_HEADER;
            PARAMS;
            SWITCH_SECTION;

            MONOPLUS;
            MONOMINUS;
            MONONOT = '!';
            MONOTWIDDLE = '~';
            MONOSTAR;
            ADDRESSOF;
            PREINC;
            PREDEC;
            POSTINC;
            POSTDEC;
            PARENS;
            INDEX;
            APPLY;
            ARGS;
            NEW;
            STATIC_CONSTRUCTOR;

            RETURN = 'return';
            PRIVATE = 'private';
            PUBLIC = 'public';
            PROTECTED = 'protected';
            STATIC = 'static';
            PRIVATE = 'private';
            TRY = 'try';
            CATCH = 'catch';
            FINALLY = 'finally';
            THROW = 'throw';
            ELSE = 'else';
            BREAK = 'break';

            OPEN_BRACKET='[';
            CLOSE_BRACKET=']';
            OPEN_BRACE='{';
            CLOSE_BRACE='}';
            LPAREN='(';
            NULL_COALESCE='??';
            IF='if';

            ASSIGN = '=';

            PLUS_ASSIGN = '+=';
            MINUS_ASSIGN = '-=';
            STAR_ASSIGN = '*=';
            DIV_ASSIGN = '/=';
            MOD_ASSIGN = '%=';

            BIT_AND_ASSIGN = '&=';
            BIT_OR_ASSIGN = '|=';
            BIT_XOR_ASSIGN = '^=';

            LEFT_SHIFT_ASSIGN = '<<=';
            RIGHT_SHIFT_ASSIGN;

            UNSIGNED_RIGHT_SHIFT_ASSIGN;  /* not in C#: >>>= */

            COND_EXPR;  // (<x> ? <y> : <z>)
            RIGHT_SHIFT;
            INSTANCEOF;

            LOG_OR = '||';
            LOG_AND = '&&';
            BIT_OR = '|';
            BIT_XOR = '^';
            BIT_AND = '&';

            NOT_EQUAL = '!=';
            EQUAL = '==';

            LTHAN = '<';
            LTE = '<=';
            GTE = '>=';

            LEFT_SHIFT = '<<';
            RIGHT_SHIFT;
            UNSIGNED_RIGHT_SHIFT;  /* not in C#: >>> */
            
            SUPER;
            LONGNUMBER;

            PLUS = '+';
            

            DIV = '/';
            MOD = '%';
            STAR = '*';

            TYPE;
            ENUM_BODY;
            TYPE_PARAM_CONSTRAINT;
            UNARY_EXPR;
            CAST_EXPR;
            
            EXCEPTION;

            PAYLOAD;   // carries arbitrary text for the output file
            PAYLOAD_LIST;
            JAVAWRAPPER;
            JAVAWRAPPEREXPRESSION;
            JAVAWRAPPERARGUMENT;
            SEP;
            KGHOLE;
}

@namespace { RusticiSoftware.Translator.CSharp }

@lexer::header       
{
	//using System.Collections.Generic;
	using Debug = System.Diagnostics.Debug;
}

@lexer::members {
	// Preprocessor Data Structures - see lexer section below and PreProcessor.cs
	protected Dictionary<string,string> MacroDefines = new Dictionary<string,string>();	
	protected Stack<bool> Processing = new Stack<bool>();

	// Uggh, lexer rules don't return values, so use a stack to return values.
	protected Stack<bool> Returns = new Stack<bool>();
}

@members
{
	protected bool is_class_modifier() 
	{
		return false;
	}
}

compilation_unit:
	namespace_body[true];

namespace_declaration:
	'namespace'   qualified_identifier   namespace_block   ';'? ;
namespace_block:
	'{'   namespace_body[false]   '}' ;
namespace_body[bool bGlobal]:
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
// Identifiers
qualified_identifier:
	identifier ('.' identifier)*;
namespace_name
	: namespace_or_type_name ;

modifiers:
	modifier+ ;
modifier: 
	'new' | 'public' | 'protected' | 'private' | 'internal' | 'unsafe' | 'abstract' | 'sealed' | 'static'
	| 'readonly' | 'volatile' | 'extern' | 'virtual' | 'override';
	
class_member_declaration:
	attributes?
	m=modifiers?
	( 'const'   type   constant_declarators   ';'
	| event_declaration		// 'event'
	| 'partial' ('void' method_declaration 
			   | interface_declaration 
			   | class_declaration 
			   | struct_declaration)
	| interface_declaration	// 'interface'
	| 'void'   method_declaration
	| type ( (member_name   '(') => method_declaration
		   | (member_name   '{') => property_declaration
		   | (member_name   '.'   'this') => type_name '.' indexer_declaration
		   | indexer_declaration	//this
	       | field_declaration      // qid
	       | operator_declaration
	       )
//	common_modifiers// (method_modifiers | field_modifiers)
	
	| class_declaration		// 'class'
	| struct_declaration	// 'struct'	   
	| enum_declaration		// 'enum'
	| delegate_declaration	// 'delegate'
	| conversion_operator_declaration
	| constructor_declaration	//	| static_constructor_declaration
	| destructor_declaration
	) 
	;

primary_expression: 
	('this'    brackets) => 'this'   brackets   primary_expression_part*
// keving: this doesn't look right:
	| ('base'   brackets) => 'this'   brackets   primary_expression_part*
	| primary_expression_start   primary_expression_part*
	| 'new' (   (object_creation_expression   ('.'|'->'|'[')) => 
					object_creation_expression   primary_expression_part+ 		// new Foo(arg, arg).Member
				// try the simple one first, this has no argS and no expressions
				// symantically could be object creation
				| (delegate_creation_expression) => delegate_creation_expression// new FooDelegate (MyFunction)
				| object_creation_expression
				| anonymous_object_creation_expression)							// new {int X, string Y} 
	| sizeof_expression						// sizeof (struct)
	| checked_expression            		// checked (...
	| unchecked_expression          		// unchecked {...}
	| default_value_expression      		// default
	| anonymous_method_expression			// delegate (int foo) {}
	;

primary_expression_start:
	predefined_type            
	| (identifier    generic_argument_list) => identifier   generic_argument_list
	| identifier ('::'   identifier)?
	| 'this' 
	| 'base'
	| paren_expression
	| typeof_expression             // typeof(Foo).Name
	| literal
	;

primary_expression_part:
	 access_identifier
	| brackets_or_arguments 
	| '++'
	| '--' ;
access_identifier:
	access_operator   type_or_generic ;
access_operator:
	'.'  |  '->' ;
brackets_or_arguments:
	brackets | arguments ;
brackets:
	'['   expression_list?   ']' ;	
paren_expression:	
	'('   expression   ')' ;
arguments: 
	'('   argument_list?   ')' ;
argument_list: 
	argument (',' argument)*;
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
rank_specifier: 
	'['   dim_separators?   ']' ;
dim_separators: 
	','+ ;

delegate_creation_expression: 
	// 'new'   
	type_name   '('   type_name   ')' ;
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
array_creation_expression:
	'new'   
		(type   ('['   expression_list   ']'   
					( rank_specifiers?   array_initializer?	// new int[4]
					// | invocation_part*
					| ( ((arguments   ('['|'.'|'->')) => arguments   invocation_part)// new object[2].GetEnumerator()
					  | invocation_part)*   arguments
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
	'sizeof'   '('   unmanaged_type   ')';
checked_expression: 
	'checked'   '('   expression   ')' ;
unchecked_expression: 
	'unchecked'   '('   expression   ')' ;
default_value_expression: 
	'default'   '('   type   ')' ;
anonymous_method_expression:
	'delegate'   explicit_anonymous_function_signature?   block;
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
		( '('   argument_list?   ')'   object_or_collection_initializer?  
		  | object_or_collection_initializer )
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
	'typeof'   '('   ((unbound_type_name) => unbound_type_name
					  | type 
					  | 'void')   ')' ;
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

type_name: 
	namespace_or_type_name ;
namespace_or_type_name:
	 type_or_generic   ('::' type_or_generic)? ('.'   type_or_generic)* ;
type_or_generic:
	(identifier   generic_argument_list) => identifier   generic_argument_list
	| identifier ;

qid:		// qualified_identifier v2
	qid_start   qid_part*
	;
qid_start:
	predefined_type
	| (identifier   generic_argument_list)	=> identifier   generic_argument_list
//	| 'this'
//	| 'base'
	| identifier   ('::'   identifier)?
	| literal 
	;		// 0.ToString() is legal


qid_part:
	access_identifier ;

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
non_nullable_type:
	(predefined_type | type_name)
		(   rank_specifiers   '*'*
			| ('*'+)?
		)
	| 'void'   '*'+ ;
	
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
	| primary_or_array_creation_expression
	| '+'   unary_expression 
	| '-'   unary_expression 
	| '!'   unary_expression 
	| '~'   unary_expression 
	| pre_increment_expression 
	| pre_decrement_expression 
	| pointer_indirection_expression
	| addressof_expression 
	;
cast_expression:
	'('   type   ')'   unary_expression ;
assignment_operator:
	'=' | '+=' | '-=' | '*=' | '/=' | '%=' | '&=' | '|=' | '^=' | '<<=' | '>' '>=' ;
pre_increment_expression: 
	'++'   unary_expression ;
pre_decrement_expression: 
	'--'   unary_expression ;
pointer_indirection_expression:
	'*'   unary_expression ;
addressof_expression:
	'&'   unary_expression ;

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
	unary_expression (  ('*'|'/'|'%')   unary_expression)*	;
additive_expression:
	multiplicative_expression (('+'|'-')   multiplicative_expression)* ;
// >> check needed (no whitespace)
shift_expression:
	additive_expression (('<<'|'>' '>') additive_expression)* ;
relational_expression:
	shift_expression
		(	(('<'|'>'|'>='|'<=')	shift_expression)
			| (('is'|'as')   non_nullable_type)
		)* ;
equality_expression:
	relational_expression
	   (('=='|'!=')   relational_expression)* ;
and_expression:
	equality_expression ('&'   equality_expression)* ;
exclusive_or_expression:
	and_expression ('^'   and_expression)* ;
inclusive_or_expression:
	exclusive_or_expression   ('|'   exclusive_or_expression)* ;
conditional_and_expression:
	inclusive_or_expression   ('&&'   inclusive_or_expression)* ;
conditional_or_expression:
	conditional_and_expression  ('||'   conditional_and_expression)* ;

null_coalescing_expression:
	conditional_or_expression   ('??'   conditional_or_expression)* ;
conditional_expression:
	null_coalescing_expression   ('?'   expression   ':'   expression)? ;
      
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
	positional_argument (',' positional_argument)* ;
positional_argument: 
	attribute_argument_expression ;
named_argument_list: 
	named_argument (',' named_argument)* ;
named_argument: 
	identifier   '='   attribute_argument_expression ;
attribute_argument_expression: 
	expression ;

///////////////////////////////////////////////////////
//	Class Section
///////////////////////////////////////////////////////

class_declaration:
	'class'  type_or_generic   class_base?   type_parameter_constraints_clauses?   class_body   ';'? ;
class_base:
	// syntactically base class vs interface name is the same
	//':'   class_type (','   interface_type_list)? ;
	':'   interface_type_list ;
	
interface_type_list:
	type (','   type)* ;

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
	variable_declarators   ';'	;
variable_declarators:
	variable_declarator (','   variable_declarator)* ;
variable_declarator:
	type_name ('='   variable_initializer)? ;		// eg. event EventHandler IInterface.VariableName = Foo;

///////////////////////////////////////////////////////
method_declaration:
	method_header   method_body ;
method_header:
	member_name  '('   formal_parameter_list?   ')'   type_parameter_constraints_clauses? ;
method_body:
	block ;
member_name:
	qid ;		// IInterface<int>.Method logic added.

///////////////////////////////////////////////////////
property_declaration:
	member_name   '{'   accessor_declarations   '}' ;
accessor_declarations:
	attributes?
		(get_accessor_declaration   attributes?   set_accessor_declaration?
		| set_accessor_declaration   attributes?   get_accessor_declaration?) ;
get_accessor_declaration:
	accessor_modifier?   'get'   accessor_body ;
set_accessor_declaration:
	accessor_modifier?   'set'   accessor_body ;
accessor_modifier:
	'public' | 'protected' | 'private' | 'internal' ;
accessor_body:
	block ;

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
enum_declaration:
	'enum'   identifier   enum_base?   enum_body   ';'? ;
enum_base:
	':'   integral_type ;
enum_body:
	'{' (enum_member_declarations ','?)?   '}' ;
enum_member_declarations:
	enum_member_declaration (',' enum_member_declaration)* ;
enum_member_declaration:
	attributes?   identifier   ('='   expression)? ;
//enum_modifiers:
//	enum_modifier+ ;
//enum_modifier:
//	'new' | 'public' | 'protected' | 'internal' | 'private' ;
integral_type: 
	'sbyte' | 'byte' | 'short' | 'ushort' | 'int' | 'uint' | 'long' | 'ulong' | 'char' ;

// B.2.12 Delegates
delegate_declaration:
	'delegate'   return_type   identifier  variant_generic_parameter_list?   
		'('   formal_parameter_list?   ')'   type_parameter_constraints_clauses?   ';' ;
delegate_modifiers:
	modifier+ ;
// 4.0
variant_generic_parameter_list:
	'<'   variant_type_parameters   '>' ;
variant_type_parameters:
	variant_type_variable_name (',' variant_type_variable_name)* ;
variant_type_variable_name:
	attributes?   variance_annotation?   type_variable_name ;
variance_annotation:
	'in' | 'out' ;

type_parameter_constraints_clauses:
	type_parameter_constraints_clause   (','   type_parameter_constraints_clause)* ;
type_parameter_constraints_clause:
	'where'   type_variable_name   ':'   type_parameter_constraint_list ;
// class, Circle, new()
type_parameter_constraint_list:                                                   
    ('class' | 'struct')   (','   secondary_constraint_list)?   (','   constructor_constraint)?
	| secondary_constraint_list   (','   constructor_constraint)?
	| constructor_constraint ;
//primary_constraint:
//	class_type
//	| 'class'
//	| 'struct' ;
secondary_constraint_list:
	secondary_constraint (',' secondary_constraint)* ;
secondary_constraint:
	type_name ;	// | type_variable_name) ;
type_variable_name: 
	identifier ;
constructor_constraint:
	'new'   '('   ')' ;
return_type:
	type
	|  'void';
formal_parameter_list:
	formal_parameter (',' formal_parameter)* ;
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
	'params'   type   identifier ;

///////////////////////////////////////////////////////
interface_declaration:
	'interface'   identifier   variant_generic_parameter_list? 
    	interface_base?   type_parameter_constraints_clauses?   interface_body   ';'? ;
interface_modifiers: 
	modifier+ ;
interface_base: 
   	':' interface_type_list ;
interface_body:
	'{'   interface_member_declarations?   '}' ;
interface_member_declarations:
	interface_member_declaration+ ;
interface_member_declaration:
	attributes?    modifiers?
		('void'   interface_method_declaration
		| interface_event_declaration
		| type   ( (member_name   '(') => interface_method_declaration
		         | (member_name   '{') => interface_property_declaration 
				 | interface_indexer_declaration)
		) 
		;
interface_property_declaration: 
	identifier   '{'   interface_accessor_declarations   '}' ;
interface_method_declaration:
	identifier   generic_argument_list?
	    '('   formal_parameter_list?   ')'   type_parameter_constraints_clauses?   ';' ;
interface_event_declaration: 
	//attributes?   'new'?   
	'event'   type   identifier   ';' ; 
interface_indexer_declaration: 
	// attributes?    'new'?    type   
	'this'   '['   formal_parameter_list   ']'   '{'   interface_accessor_declarations   '}' ;
interface_accessor_declarations:
	attributes?   
		(interface_get_accessor_declaration   attributes?   interface_set_accessor_declaration?
		| interface_set_accessor_declaration   attributes?   interface_get_accessor_declaration?) ;
interface_get_accessor_declaration:
	'get'   ';' ;		// no body / modifiers
interface_set_accessor_declaration:
	'set'   ';' ;		// no body / modifiers
method_modifiers:
	modifier+ ;
	
///////////////////////////////////////////////////////
struct_declaration:
	'struct'   type_or_generic   struct_interfaces?   type_parameter_constraints_clauses?   struct_body   ';'? ;
struct_modifiers:
	struct_modifier+ ;
struct_modifier:
	'new' | 'public' | 'protected' | 'internal' | 'private' | 'unsafe' ;
struct_interfaces:
	':'   interface_type_list;
struct_body:
	'{'   struct_member_declarations?   '}';
struct_member_declarations:
	struct_member_declaration+ ;
struct_member_declaration:
	attributes?   m=modifiers?
	( 'const'   type   constant_declarators   ';'
	| event_declaration		// 'event'
	| 'partial' (method_declaration 
			   | interface_declaration 
			   | class_declaration 
			   | struct_declaration)

	| interface_declaration	// 'interface'
	| class_declaration		// 'class'
	| 'void'   method_declaration
	| type ( (member_name   '(') => method_declaration
		   | (member_name   '{') => property_declaration
		   | (member_name   '.'   'this') => type_name '.' indexer_declaration
		   | indexer_declaration	//this
	       | field_declaration      // qid
	       | operator_declaration
	       )
//	common_modifiers// (method_modifiers | field_modifiers)
	
	| struct_declaration	// 'struct'	   
	| enum_declaration		// 'enum'
	| delegate_declaration	// 'delegate'
	| conversion_operator_declaration
	| constructor_declaration	//	| static_constructor_declaration
	) 
	;


///////////////////////////////////////////////////////
indexer_declaration:
	indexer_declarator   '{'   accessor_declarations   '}' ;
indexer_declarator:
	//(type_name '.')?   
	'this'   '['   formal_parameter_list   ']' ;
	
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
constructor_declaration:
	constructor_declarator   constructor_body ;
constructor_declarator:
	identifier   '('   formal_parameter_list?   ')'   constructor_initializer? ;
constructor_initializer:
	':'   ('base' | 'this')   '('   argument_list?   ')' ;
constructor_body:
	block ;

///////////////////////////////////////////////////////
//static_constructor_declaration:
//	identifier   '('   ')'  static_constructor_body ;
//static_constructor_body:
//	block ;

///////////////////////////////////////////////////////
destructor_declaration:
	'~'  identifier   '('   ')'    destructor_body ;
destructor_body:
	block ;

///////////////////////////////////////////////////////
invocation_expression:
	invocation_start   (((arguments   ('['|'.'|'->')) => arguments   invocation_part)
						| invocation_part)*   arguments ;
invocation_start:
	predefined_type 
	| (identifier    generic_argument_list)	=> identifier   generic_argument_list
	| 'this' 
	| 'base'
	| identifier   ('::'   identifier)?
	| typeof_expression             // typeof(Foo).Name
	;
invocation_part:
	 access_identifier
	| brackets ;

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
	'unsafe'   block;
labeled_statement:
	identifier   ':'   statement ;
declaration_statement:
	(local_variable_declaration 
	| local_constant_declaration) ';' ;
local_variable_declaration:
	local_variable_type   local_variable_declarators ;
local_variable_type:
	('var') => 'var'
	| ('dynamic') => 'dynamic'
	| type ;
local_variable_declarators:
	local_variable_declarator (',' local_variable_declarator)* ;
local_variable_declarator:
	identifier ('='   local_variable_initializer)? ; 
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
	'if'   '('   boolean_expression   ')'   embedded_statement (('else') => else_statement)?
	;
else_statement:
	'else'   embedded_statement	;
switch_statement:
	'switch'   '('   expression   ')'   switch_block ;
switch_block:
	'{'   switch_sections?   '}' ;
switch_sections:
	switch_section+ ;
switch_section:
	switch_labels   statement_list ;
switch_labels:
	switch_label+ ;
switch_label:
	('case'   constant_expression   ':')
	| ('default'   ':') ;
iteration_statement:
	while_statement
	| do_statement
	| for_statement
	| foreach_statement ;
while_statement:
	'while'   '('   boolean_expression   ')'   embedded_statement ;
do_statement:
	'do'   embedded_statement   'while'   '('   boolean_expression   ')'   ';' ;
for_statement:
	'for'   '('   for_initializer?   ';'   for_condition?   ';'   for_iterator?   ')'   embedded_statement ;
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
	'foreach'   '('   local_variable_type   identifier   'in'   expression   ')'   embedded_statement ;
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
	'return'   expression?   ';' ;
throw_statement:
	'throw'   expression?   ';' ;
try_statement:
      'try'   block   ( catch_clauses   finally_clause?
					  | finally_clause);
//TODO one or both
catch_clauses:
	'catch'   (specific_catch_clauses | general_catch_clause) ;
specific_catch_clauses:
	specific_catch_clause   ('catch'   (specific_catch_clause | general_catch_clause))*;
specific_catch_clause:
	'('   class_type   identifier?   ')'   block ;
general_catch_clause:
	block ;
finally_clause:
	'finally'   block ;
checked_statement:
	'checked'   block ;
unchecked_statement:
	'unchecked'   block ;
lock_statement:
	'lock'   '('  expression   ')'   embedded_statement ;
using_statement:
	'using'   '('    resource_acquisition   ')'    embedded_statement ;
resource_acquisition:
	(local_variable_declaration) => local_variable_declaration
	| expression ;
yield_statement:
	'yield'   ('return'   expression   ';'
	          | 'break'   ';') ;

///////////////////////////////////////////////////////
//	Lexar Section
///////////////////////////////////////////////////////

predefined_type:
	  'bool' | 'byte'   | 'char'   | 'decimal' | 'double' | 'float'  | 'int'    | 'long'   | 'object' | 'sbyte'  
	| 'short'  | 'string' | 'uint'   | 'ulong'  | 'ushort' ;

identifier:
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
	| NUMBER
	| Hex_number
	| Character_literal
	| STRINGLITERAL
	| Verbatim_string_literal
	| TRUE
	| FALSE
	| NULL 
	;

///////////////////////////////////////////////////////

TRUE : 'true';
FALSE: 'false' ;
NULL : 'null' ;
DOT : '.' ;
PTR : '->' ;
MINUS : '-' ;
GT : '>' ;
USING : 'using';
ENUM : 'enum';
IF: 'if';
ELIF: 'elif';
ENDIF: 'endif';
DEFINE: 'define';
UNDEF: 'undef';
SEMI: ';';
RPAREN: ')';

WS:
    (' '  |  '\r'  |  '\t'  |  '\n'  ) 
    { Skip(); } ;
fragment
TS:
    (' '  |  '\t'  ) 
    { Skip(); } ;
DOC_LINE_COMMENT
    : 	('///' ~('\n'|'\r')*  ('\r' | '\n')+)
    {$channel=Hidden;} ;
LINE_COMMENT
    :	('//' ~('\n'|'\r')*  ('\r' | '\n')+)
    {$channel=Hidden;} ;
COMMENT:
   '/*'
   (options {greedy=false;} : . )* 
   '*/'
	{$channel=Hidden;} ;
STRINGLITERAL
	:
	'"' (EscapeSequence | ~('"' | '\\'))* '"' ;
Verbatim_string_literal:
	'@'   '"' Verbatim_string_literal_character* '"' ;
fragment
Verbatim_string_literal_character:
	'"' '"' | ~('"') ;
NUMBER:
	Decimal_digits INTEGER_TYPE_SUFFIX? ;
// For the rare case where 0.ToString() etc is used.
GooBall
@after		
{
	CommonToken int_literal = new CommonToken(NUMBER, $dil.text);
	CommonToken dot = new CommonToken(DOT, ".");
	CommonToken iden = new CommonToken(IDENTIFIER, $s.text);
	
	Emit(int_literal); 
	Emit(dot); 
	Emit(iden); 
	Console.Error.WriteLine("\tFound GooBall {0}", $text); 
}
	:
	dil = Decimal_integer_literal d = '.' s=GooBallIdentifier
	;

fragment GooBallIdentifier
	: IdentifierStart IdentifierPart* ;

//---------------------------------------------------------
Real_literal:
	Decimal_digits   '.'   Decimal_digits   Exponent_part?   Real_type_suffix?
	| '.'   Decimal_digits   Exponent_part?   Real_type_suffix?
	| Decimal_digits   Exponent_part   Real_type_suffix?
	| Decimal_digits   Real_type_suffix ;
Character_literal:
	'\''
    (   EscapeSequence
	// upto 3 multi byte unicode chars
    |   ~( '\\' | '\'' | '\r' | '\n' )        
    |   ~( '\\' | '\'' | '\r' | '\n' ) ~( '\\' | '\'' | '\r' | '\n' )
    |   ~( '\\' | '\'' | '\r' | '\n' ) ~( '\\' | '\'' | '\r' | '\n' ) ~( '\\' | '\'' | '\r' | '\n' )
    )
    '\'' ;
IDENTIFIER:
    IdentifierStart IdentifierPart* ;
Pragma:
	//	ignore everything after the pragma since the escape's in strings etc. are different
	'#'   TS*   ('pragma' | 'region' | 'endregion' | 'line' | 'warning' | 'error') ~('\n'|'\r')*  ('\r' | '\n')+
    { Skip(); } ;
PREPROCESSOR_DIRECTIVE:
	PP_CONDITIONAL;
fragment
PP_CONDITIONAL:
	(IF_TOKEN
	| DEFINE_TOKEN
	| ELSE_TOKEN
	| ENDIF_TOKEN 
	| UNDEF_TOKEN)   TS*   (LINE_COMMENT?  |  ('\r' | '\n')+) ;
fragment
IF_TOKEN
	@init { bool process = true; }:
	('#'   TS*  'if'   TS+   ppe = PP_EXPRESSION)
{
    // if our parent is processing check this if
    Debug.Assert(Processing.Count > 0, "Stack underflow preprocessing.  IF_TOKEN");
    if (Processing.Count > 0 && Processing.Peek())
	    Processing.Push(Returns.Pop());
	else
		Processing.Push(false);
} ;
fragment
DEFINE_TOKEN:
	'#'   TS*   'define'   TS+   define = IDENTIFIER
	{
		MacroDefines.Add($define.Text, "");
	} ;
fragment
UNDEF_TOKEN:
	'#'   TS*   'undef'   TS+   define = IDENTIFIER
	{
		if (MacroDefines.ContainsKey($define.Text))
			MacroDefines.Remove($define.Text);
	} ;
fragment
ELSE_TOKEN:
	( '#'   TS*   e = 'else'
	| '#'   TS*   'elif'   TS+   PP_EXPRESSION)
	{
		// We are in an elif
       	if ($e == null)
		{
		    Debug.Assert(Processing.Count > 0, "Stack underflow preprocessing.  ELIF_TOKEN");
			if (Processing.Count > 0 && Processing.Peek() == false)
			{
				Processing.Pop();
				// if our parent was processing, do else logic
			    Debug.Assert(Processing.Count > 0, "Stack underflow preprocessing.  ELIF_TOKEN2");
				if (Processing.Count > 0 && Processing.Peek())
					Processing.Push(Returns.Pop());
				else
					Processing.Push(false);
			}
			else
			{
				Processing.Pop();
				Processing.Push(false);
			}
		}
		else
		{
			// we are in a else
			if (Processing.Count > 0)
			{
				bool bDoElse = !Processing.Pop();

				// if our parent was processing				
			    Debug.Assert(Processing.Count > 0, "Stack underflow preprocessing, ELSE_TOKEN");
				if (Processing.Count > 0 && Processing.Peek())
					Processing.Push(bDoElse);
				else
					Processing.Push(false);
			}
		}
		Skip();
	} ;
fragment
ENDIF_TOKEN:
	'#'   TS*   'endif'
	{
		if (Processing.Count > 0)
			Processing.Pop();
		Skip();
	} ;
	
	
	
	
fragment
PP_EXPRESSION:
	PP_OR_EXPRESSION;
fragment
PP_OR_EXPRESSION:
	PP_AND_EXPRESSION   TS*   ('||'   TS*   PP_AND_EXPRESSION   TS* )* ;
fragment
PP_AND_EXPRESSION:
	PP_EQUALITY_EXPRESSION   TS*   ('&&'   TS*   PP_EQUALITY_EXPRESSION   TS* )* ;
fragment
PP_EQUALITY_EXPRESSION:
	PP_UNARY_EXPRESSION   TS*   (('=='| ne = '!=')   TS*   PP_UNARY_EXPRESSION
		{ 
			bool rt1 = Returns.Pop(), rt2 = Returns.Pop();
			Returns.Push(rt1 == rt2 == ($ne == null));
		}
		TS* )*
	;
fragment
PP_UNARY_EXPRESSION:
	pe = PP_PRIMARY_EXPRESSION
	| '!'   TS*   ue = PP_UNARY_EXPRESSION  { Returns.Push(!Returns.Pop()); } 
	;
fragment
PP_PRIMARY_EXPRESSION:
	IDENTIFIER	
	{ 
		Returns.Push(MacroDefines.ContainsKey($IDENTIFIER.Text));
	}
	| '('   PP_EXPRESSION   ')'
	;


	
fragment
IdentifierStart
	:	'@' | '_' | 'A'..'Z' | 'a'..'z' ;
fragment
IdentifierPart
: 'A'..'Z' | 'a'..'z' | '0'..'9' | '_' ;
fragment
EscapeSequence 
    :   '\\' (
                 'b' 
             |   't' 
             |   'n' 
             |   'f' 
             |   'r'
             |   'v'
             |   'a'
             |   '\"' 
             |   '\'' 
             |   '\\'
             |   ('0'..'3') ('0'..'7') ('0'..'7')
             |   ('0'..'7') ('0'..'7') 
             |   ('0'..'7')
             |   'x'   HEX_DIGIT
             |   'x'   HEX_DIGIT   HEX_DIGIT
             |   'x'   HEX_DIGIT   HEX_DIGIT  HEX_DIGIT
             |   'x'   HEX_DIGIT   HEX_DIGIT  HEX_DIGIT  HEX_DIGIT
             |   'u'   HEX_DIGIT   HEX_DIGIT  HEX_DIGIT  HEX_DIGIT
             |   'U'   HEX_DIGIT   HEX_DIGIT  HEX_DIGIT  HEX_DIGIT  HEX_DIGIT  HEX_DIGIT  HEX_DIGIT
             ) ;     
fragment
Decimal_integer_literal:
	Decimal_digits   INTEGER_TYPE_SUFFIX? ;
//--------------------------------------------------------
Hex_number:
	'0'('x'|'X')   HEX_DIGITS   INTEGER_TYPE_SUFFIX? ;
fragment
Decimal_digits:
	DECIMAL_DIGIT+ ;
fragment
DECIMAL_DIGIT:
	'0'..'9' ;
fragment
INTEGER_TYPE_SUFFIX:
	'U' | 'u' | 'L' | 'l' | 'UL' | 'Ul' | 'uL' | 'ul' | 'LU' | 'Lu' | 'lU' | 'lu' ;
fragment HEX_DIGITS:
	HEX_DIGIT+ ;
fragment HEX_DIGIT:
	'0'..'9'|'A'..'F'|'a'..'f' ;
fragment
Exponent_part:
	('e'|'E')   Sign?   Decimal_digits;
fragment
Sign:
	'+'|'-' ;
fragment
Real_type_suffix:
	'F' | 'f' | 'D' | 'd' | 'M' | 'm' ;	
	
// Testing rules - so you can just use one file with a list of items
assignment_list:
	(assignment ';')+ ;
field_declarations:
	(attributes?   modifiers?   type   field_declaration)+ ;
property_declaration_list:
	(attributes?   modifiers?   type   property_declaration)+ ;
constant_declarations:
	constant_declaration+;
literals:
	literal+ ;
delegate_declaration_list:
	(attributes?   modifiers?   delegate_declaration)+ ;
local_variable_declaration_list:
	(local_variable_declaration ';')+ ;
local_variable_initializer_list:
	(local_variable_initializer ';')+ ;
expression_list_test:
	(expression ';')+ ;
unary_expression_list:
	(unary_expression ';')+ ;
invocation_expression_list:
	(invocation_expression ';')+ ;
primary_expression_list:
	(primary_expression ';')+ ;
non_assignment_expression_list:
	(non_assignment_expression ';')+ ;
method_declarations:
	(modifiers? ('void' | type) method_declaration)+ ;	
