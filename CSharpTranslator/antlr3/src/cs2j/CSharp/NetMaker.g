tree grammar NetMaker;

options {
    tokenVocab=cs;
    ASTLabelType=CommonTree;
	output=AST;
    language=CSharp2;
    superClass='RusticiSoftware.Translator.CSharp.CommonWalker';
}

@namespace { RusticiSoftware.Translator.CSharp }

@members
{
}

compilation_unit:
	^(PACKAGE PAYLOAD modifiers? type_declaration);

type_declaration:
	class_declaration
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
	'new' | 'public' | 'protected' | 'private' | 'abstract' | 'sealed' | 'static'
	| 'readonly' | 'volatile' | 'extern' | 'virtual' | 'override' | FINAL ;
	
class_member_declaration:
    ^(CONST attributes? modifiers? type constant_declarators)
    | ^(EVENT attributes? modifiers? event_declaration)
    | ^(METHOD attributes? modifiers? type member_name type_parameter_constraints_clauses? type_parameter_list? formal_parameter_list? method_body exception*)
    | ^(INTERFACE attributes? modifiers? interface_declaration)
    | ^(CLASS attributes? modifiers? class_declaration)
    | ^(INDEXER attributes? modifiers? type type_name? indexer_declaration)
    | ^(FIELD attributes? modifiers? type field_declaration)
    | ^(OPERATOR attributes? modifiers? type operator_declaration)
    | ^(ENUM attributes? modifiers? enum_declaration)
    | ^(DELEGATE attributes? modifiers? delegate_declaration)
    | ^(CONVERSION_OPERATOR attributes? modifiers? conversion_operator_declaration)
    | ^(CONSTRUCTOR attributes? modifiers? identifier  formal_parameter_list? block)
    | ^(DESTRUCTOR attributes? modifiers? destructor_declaration)
    ;
// class_member_declaration:
// 	attributes?
// 	m=modifiers?
// 	( 'const'   type   constant_declarators   ';'
// 	| event_declaration		// 'event'
// 	| 'partial' (method_declaration 
// 			   | interface_declaration 
// 			   | class_declaration 
// 			   | struct_declaration)
// 	| interface_declaration	// 'interface'
// //	| 'void'   method_declaration
// 	| type ( (member_name   '(') => method_declaration
// 		   | (member_name   '{') => property_declaration
// 		   | (member_name   '.'   'this') => type_name '.' indexer_declaration
// 		   | indexer_declaration	//this
// 	       | field_declaration      // qid
// 	       | operator_declaration
// 	       )
// //	common_modifiers// (method_modifiers | field_modifiers)
// 	
// 	| class_declaration		// 'class'
// 	| struct_declaration	// 'struct'	   
// 	| enum_declaration		// 'enum'
// 	| delegate_declaration	// 'delegate'
// 	| conversion_operator_declaration
// 	| constructor_declaration	//	| static_constructor_declaration
// 	| destructor_declaration
// 	) 
// 	;
// 

exception:
    EXCEPTION;

primary_expression: 
    ^(INDEX expression expression_list?)
    | ^(APPLY expression argument_list?)
    | ^(POSTINC expression)
    | ^(POSTDEC expression)
    | primary_expression_start
    | ^(access_operator expression type_or_generic)
//	('this'    brackets) => 'this'   brackets   primary_expression_part*
//	| ('base'   brackets) => 'this'   brackets   primary_expression_part*
//	| primary_expression_start   primary_expression_part*
    | ^(NEW type argument_list? object_or_collection_initializer?)
	| 'new' (   
				// try the simple one first, this has no argS and no expressions
				// symantically could be object creation
				 (delegate_creation_expression) => delegate_creation_expression// new FooDelegate (MyFunction)
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
    | identifier
	| ^('::' identifier identifier)
	| 'this' 
	| SUPER
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
	^(ARGS argument+);
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
	'['   /*dim_separators?*/   ']' ;
// keving
// dim_separators: 
//	','+ ;

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
	^('new'   
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
		)) ;
array_initializer:
	'{'   variable_initializer_list?   ','?   '}' ;
variable_initializer_list:
	variable_initializer (',' variable_initializer)* ;
variable_initializer:
	expression	| array_initializer ;
sizeof_expression:
	^('sizeof'  unmanaged_type );
checked_expression: 
	^('checked' expression ) ;
unchecked_expression: 
	^('unchecked' expression ) ;
default_value_expression: 
	^('default' type   ) ;
anonymous_method_expression:
	^('delegate'   explicit_anonymous_function_signature?   block);
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
	^('typeof'  (unbound_type_name | type | 'void') ) ;
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
	 type_or_generic
    | ^('::' namespace_or_type_name type_or_generic) 
    | ^('.'   namespace_or_type_name type_or_generic) ;
type_or_generic:
	(identifier   generic_argument_list) => identifier   generic_argument_list
	| identifier ;

qid:		// qualified_identifier v2
    ^(access_operator qid type_or_generic) 
	| qid_start  
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
    ^(TYPE (predefined_type | type_name | 'void')  rank_specifiers? '*'* '?'?);
non_nullable_type:
    type;
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

    //(cast_expression) => cast_expression
	^(CAST_EXPR type unary_expression) 
	| primary_or_array_creation_expression
	| ^(MONOPLUS unary_expression)
	| ^(MONOMINUS unary_expression)
	| ^(MONONOT unary_expression)
	| ^(MONOTWIDDLE unary_expression)
	| ^(PREINC unary_expression)
	| ^(PREDEC unary_expression)
	| ^(MONOSTAR unary_expression)
	| ^(ADDRESSOF unary_expression)
	| ^(PARENS expression) 
	;
//cast_expression:
//	'('   type   ')'   non_assignment_expression ;
assignment_operator:
	'=' | '+=' | '-=' | '*=' | '/=' | '%=' | '&=' | '|=' | '^=' | '<<=' | '>' '>=' ;
//pre_increment_expression: 
//	'++'   unary_expression ;
//pre_decrement_expression: 
//	'--'   unary_expression ;
//pointer_indirection_expression:
//	'*'   unary_expression ;
//addressof_expression:
//	'&'   unary_expression ;

non_assignment_expression:
	//'non ASSIGNment'
	(anonymous_function_signature   '=>')	=> lambda_expression
	| (query_expression) => query_expression 
	|     ^(COND_EXPR non_assignment_expression expression expression) 
        | ^('??' non_assignment_expression non_assignment_expression)
        | ^('||' non_assignment_expression non_assignment_expression)
        | ^('&&' non_assignment_expression non_assignment_expression)
        | ^('|' non_assignment_expression non_assignment_expression)
        | ^('^' non_assignment_expression non_assignment_expression)
        | ^('&' non_assignment_expression non_assignment_expression)
        | ^('==' non_assignment_expression non_assignment_expression)
        | ^('!=' non_assignment_expression non_assignment_expression)
        | ^('>' non_assignment_expression non_assignment_expression)
        | ^('<' non_assignment_expression non_assignment_expression)
        | ^('>=' non_assignment_expression non_assignment_expression)
        | ^('<=' non_assignment_expression non_assignment_expression)
        | ^(INSTANCEOF non_assignment_expression non_nullable_type)
        | ^('<<' non_assignment_expression non_assignment_expression)
        | ^('>>' non_assignment_expression non_assignment_expression)
        | ^('+' non_assignment_expression non_assignment_expression)
        | ^('-' non_assignment_expression non_assignment_expression)
        | ^('*' non_assignment_expression non_assignment_expression)
        | ^('/' non_assignment_expression non_assignment_expression)
        | ^('%' non_assignment_expression non_assignment_expression) 
 //       | ^(UNARY_EXPRESSION unary_expression)
        | unary_expression
	;

// ///////////////////////////////////////////////////////
// //	Conditional Expression Section
// ///////////////////////////////////////////////////////
// 
// multiplicative_expression:
// 	unary_expression (  ('*'|'/'|'%')   unary_expression)*	;
// additive_expression:
// 	multiplicative_expression (('+'|'-')   multiplicative_expression)* ;
// // >> check needed (no whitespace)
// shift_expression:
// 	additive_expression (('<<'|'>' '>') additive_expression)* ;
// relational_expression:
// 	shift_expression
// 		(	(('<'|'>'|'>='|'<=')	shift_expression)
// 			| (('is'|'as')   non_nullable_type)
// 		)* ;
// equality_expression:
// 	relational_expression
// 	   (('=='|'!=')   relational_expression)* ;
// and_expression:
// 	equality_expression ('&'   equality_expression)* ;
// exclusive_or_expression:
// 	and_expression ('^'   and_expression)* ;
// inclusive_or_expression:
// 	exclusive_or_expression   ('|'   exclusive_or_expression)* ;
// conditional_and_expression:
// 	inclusive_or_expression   ('&&'   inclusive_or_expression)* ;
// conditional_or_expression:
// 	conditional_and_expression  ('||'   conditional_and_expression)* ;
// 
// null_coalescing_expression:
// 	conditional_or_expression   ('??'   conditional_or_expression)* ;
// conditional_expression:
// 	null_coalescing_expression   ('?'   expression   ':'   expression)? ;
//       

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
	^(ARGS positional_argument+) ;
positional_argument: 
	attribute_argument_expression ;
named_argument_list: 
	^(ARGS named_argument+) ;
named_argument: 
	identifier   '='   attribute_argument_expression ;
attribute_argument_expression: 
	expression ;

///////////////////////////////////////////////////////
//	Class Section
///////////////////////////////////////////////////////

class_declaration:
   ^(CLASS identifier type_parameter_constraints_clauses? type_parameter_list?
         class_implements? class_body ) ;

type_parameter_list:
    (attributes? type_parameter)+ ;

type_parameter:
    identifier ;

class_extends:
	^(EXTENDS type*) ;
class_implements:
	^(IMPLEMENTS type*) ;
	
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
	variable_declarators ;
variable_declarators:
	variable_declarator (','   variable_declarator)* ;
variable_declarator:
	type_name ('='   variable_initializer)? ;		// eg. event EventHandler IInterface.VariableName = Foo;

///////////////////////////////////////////////////////
method_declaration:
	method_header   method_body ;
method_header:
    ^(METHOD_HEADER attributes? modifiers? type member_name type_parameter_constraints_clauses? type_parameter_list? formal_parameter_list?);
method_body:
	block ;
member_name:
    type_or_generic ('.' type_or_generic)*
    ;
    // keving: missing interface_type.identifier
	//identifier ;		// IInterface<int>.Method logic added.

///////////////////////////////////////////////////////

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
	^(ENUM_BODY enum_member_declarations) ;
enum_member_declarations:
	enum_member_declaration+ ;
enum_member_declaration:
	attributes?   identifier ;
//enum_modifiers:
//	enum_modifier+ ;
//enum_modifier:
//	'new' | 'public' | 'protected' | 'internal' | 'private' ;
integral_type: 
	'sbyte' | 'byte' | 'short' | 'ushort' | 'int' | 'uint' | 'long' | 'ulong' | 'char' ;

// B.2.12 Delegates
delegate_declaration:
	'delegate'   return_type   identifier   type_parameter_constraints_clauses?  variant_generic_parameter_list?   
		'('   formal_parameter_list?   ')'    ';' ;
delegate_modifiers:
	modifier+ ;
// 4.0
variant_generic_parameter_list:
	variant_type_variable_name+ ;
variant_type_variable_name:
	attributes?   variance_annotation?   type_variable_name ;
variance_annotation:
	IN | OUT ;

type_parameter_constraints_clauses:
	type_parameter_constraints_clause+ -> type_parameter_constraints_clause*;
type_parameter_constraints_clause:
    // If there are no type constraints on this variable then drop this constraint
	^(TYPE_PARAM_CONSTRAINT type_variable_name) -> 
    | ^(TYPE_PARAM_CONSTRAINT type_variable_name type_name+) ;
type_variable_name: 
	identifier ;
constructor_constraint:
	'new'   '('   ')' ;
return_type:
	type ;
formal_parameter_list:
    ^(PARAMS formal_parameter+) ;
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
	^('params'   type   identifier) ;

///////////////////////////////////////////////////////
interface_declaration:
   ^(INTERFACE identifier type_parameter_constraints_clauses?   variant_generic_parameter_list? 
    	class_extends?    interface_body ) ;
interface_modifiers: 
	modifier+ ;
interface_base: 
   	':' interface_type_list ;
interface_body:
	'{'   interface_member_declarations?   '}' ;
interface_member_declarations:
	interface_member_declaration+ ;
interface_member_declaration:
    ^(EVENT attributes? modifiers? event_declaration)
    | ^(METHOD attributes? modifiers? type identifier type_parameter_constraints_clauses? type_parameter_list? formal_parameter_list? exception*)
    | ^(INDEXER attributes? modifiers? type type_name? indexer_declaration)
		;
	
///////////////////////////////////////////////////////
// struct_declaration:
// 	'struct'   type_or_generic   struct_interfaces?   type_parameter_constraints_clauses?   struct_body   ';'? ;
// struct_modifiers:
// 	struct_modifier+ ;
// struct_modifier:
// 	'new' | 'public' | 'protected' | 'internal' | 'private' | 'unsafe' ;
// struct_interfaces:
// 	':'   interface_type_list;
// struct_body:
// 	'{'   struct_member_declarations?   '}';
// struct_member_declarations:
// 	struct_member_declaration+ ;
// struct_member_declaration:
// 	attributes?   m=modifiers?
// 	( 'const'   type   constant_declarators   ';'
// 	| event_declaration		// 'event'
// 	| 'partial' (method_declaration 
// 			   | interface_declaration 
// 			   | class_declaration 
// 			   | struct_declaration)
// 
// 	| interface_declaration	// 'interface'
// 	| class_declaration		// 'class'
// 	| 'void'   method_declaration
// 	| type ( (member_name   '(') => method_declaration
// 		   | (member_name   '{') => property_declaration
// 		   | (member_name   '.'   'this') => type_name '.' indexer_declaration
// 		   | indexer_declaration	//this
// 	       | field_declaration      // qid
// 	       | operator_declaration
// 	       )
// //	common_modifiers// (method_modifiers | field_modifiers)
// 	
// 	| struct_declaration	// 'struct'	   
// 	| enum_declaration		// 'enum'
// 	| delegate_declaration	// 'delegate'
// 	| conversion_operator_declaration
// 	| constructor_declaration	//	| static_constructor_declaration
// 	) 
// 	;


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
	| SUPER
	| identifier   ('::'   identifier)?
	| typeof_expression             // typeof(Foo).Name
	;
invocation_part:
	 access_identifier
	| brackets ;

///////////////////////////////////////////////////////

// keving: split statement into two parts, there seems to be a problem with the state
// machine if we combine statement and statement_plus. (It fails to recognise dataHelper.Add();)
statement:
    (declaration_statement) => declaration_statement 
    | statement_plus;
statement_plus:
    (identifier   ':') => labeled_statement 
    | embedded_statement 
	;
embedded_statement:
block
	| ^(IF boolean_expression SEP embedded_statement else_statement?)
    | ^('switch' expression switch_section*)
	| iteration_statement	// while, do, for, foreach
	| jump_statement		// break, continue, goto, return, throw
	| ^('try' block catch_clauses? finally_clause?)
	| checked_statement
	| unchecked_statement
	| lock_statement
	| using_statement 
	| yield_statement 
    | ^('unsafe'   block)
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
else_statement:
	'else'   embedded_statement	;
switch_section:
	^(SWITCH_SECTION switch_label+ statement_list) ;
switch_label:
	^('case'   constant_expression)
	| 'default';
iteration_statement:
	^('while' boolean_expression SEP embedded_statement)
	| do_statement
	| ^('for' for_initializer? SEP for_condition? SEP for_iterator? SEP embedded_statement)
	| ^('foreach' local_variable_type   identifier  expression SEP  embedded_statement);
do_statement:
	'do'   embedded_statement   'while'   '('   boolean_expression   ')'   ';' ;
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
jump_statement:
	break_statement
	| continue_statement
	| goto_statement
	| ^('return' expression?)
	| ^('throw'  expression?);
break_statement:
	'break'   ';' ;
continue_statement:
	'continue'   ';' ;
goto_statement:
	'goto'   ( identifier
			 | 'case'   constant_expression
			 | 'default')   ';' ;
catch_clauses:
    catch_clause+ ;
catch_clause:
	^('catch' class_type   identifier block) ;
finally_clause:
	^('finally'   block) ;
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
	| LONGNUMBER
	| Hex_number
	| Character_literal
	| STRINGLITERAL
	| Verbatim_string_literal
	| TRUE
	| FALSE
	| NULL 
	;

