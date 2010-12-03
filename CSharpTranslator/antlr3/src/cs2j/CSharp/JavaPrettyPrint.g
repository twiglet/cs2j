tree grammar JavaPrettyPrint;

options {
    tokenVocab=cs;
    ASTLabelType=CommonTree;
    language=CSharp2;
    superClass='RusticiSoftware.Translator.CSharp.CommonWalker';
    output=template;
}

@namespace { RusticiSoftware.Translator.CSharp }

@header
{
	using System.Collections;
	using System.Text;
	using System.Text.RegularExpressions;
}

@members
{

    public bool IsLast { get; set; }
    public int EmittedCommentTokenIdx { get; set; }
 
    private List<string> collectedComments = null;
    List<string> CollectedComments {
        get {
            List<string> rets = collectedComments;
            collectedComments = null;
            return rets;
        }
        set {
            if (collectedComments == null) 
                collectedComments = new List<string>();
            foreach (string c in value) {
                collectedComments.Add(c);
            }
        }
    }

    // Collect all comments from previous position to endIdx
    // comments are the text from tokens on the Hidden channel
    protected void collectComments(IToken tok) {
        // TokenIndex may be -1, no sweat we just won't collect anything
        collectComments(tok.TokenIndex);
    }
    protected void collectComments(int endIdx) {
        List<string> rets = new List<string>();
        List<IToken> toks = ((CommonTokenStream)this.GetTreeNodeStream().TokenStream).GetTokens(EmittedCommentTokenIdx,endIdx);
        if (toks != null) {
            foreach (IToken tok in toks) {
                if (tok.Channel == TokenChannels.Hidden) {
                    rets.Add(new Regex("(\\n|\\r)+").Replace(tok.Text, Environment.NewLine).Trim());
                }
            }
            EmittedCommentTokenIdx = endIdx+1;
        }
        collectedComments = rets;
    }

    protected void collectComments() {
        collectComments(((CommonTokenStream)this.GetTreeNodeStream().TokenStream).GetTokens().Count - 1);
    }

    protected string escapeJavaString(string rawStr)
    {
        StringBuilder buf = new StringBuilder(rawStr.Length * 2);
        bool seenDQ = false;
        foreach (char ch in rawStr)
        {
            switch (ch)
            {
            case '\\':
                buf.Append("\\\\");
                break;
            case '"':
                if (seenDQ)
                    buf.Append("\\\"");
                seenDQ = !seenDQ;
                break;
            case '\'':
                buf.Append("\\'");
                break;
            case '\b':
                buf.Append("\\b");
                break;
            case '\t':
                buf.Append("\\t");
                break;
            case '\n':
                buf.Append("\\n");
                break;
            case '\f':
                buf.Append("\\f");
                break;
            case '\r':
                buf.Append("\\r");
                break;
            default:
                buf.Append(ch);
                break;
            }
            if (ch != '"')
                seenDQ = false;
        }
        return buf.ToString();
    }
}

compilation_unit
:
    ^(PACKAGE nm=PAYLOAD modifiers? type_declaration[$modifiers.st] { if (IsLast) collectComments(); }) -> 
        package(now = {DateTime.Now}, includeDate = {true}, packageName = {($nm.text != null && $nm.text.Length > 0 ? $nm.text : null)}, 
            type = {$type_declaration.st},
            endComments = { CollectedComments });

type_declaration [StringTemplate modifiersST]:
    class_declaration[modifiersST] -> { $class_declaration.st }
	| struct_declaration
	| interface_declaration[modifiersST] -> { $interface_declaration.st }
	| enum_declaration[modifiersST] -> { $enum_declaration.st }
	| delegate_declaration ;
// Identifiers
qualified_identifier:
	identifier ('.' identifier)*;
namespace_name
	: namespace_or_type_name ;

modifiers:
	ms+=modifier+ -> modifiers(mods={$ms});
modifier
: 
        (m='new' | m='public' | m='protected' | m='private' | m='abstract' | m='sealed' | m='static'
        | m='readonly' | m='volatile' | m='extern' | m='virtual' | m='override' | m=FINAL)
        -> string(payload={$m.text});
	
class_member_declaration:
    ^(CONST attributes? modifiers? type constant_declarators)
    | ^(EVENT attributes? modifiers? event_declaration)
    | ^(METHOD attributes? modifiers? type method_declaration)
    | ^(INTERFACE attributes? modifiers? interface_declaration[$modifiers.st])
    | ^(CLASS attributes? modifiers? class_declaration[$modifiers.st])
    | ^(PROPERTY attributes? modifiers? type property_declaration)
    | ^(INDEXER attributes? modifiers? type type_name? indexer_declaration)
    | ^(FIELD attributes? modifiers? type field_declaration)     -> field(modifiers={$modifiers.st}, type={$type.st}, field={$field_declaration.st}) 
    | ^(OPERATOR attributes? modifiers? type operator_declaration)
    | ^(ENUM attributes? modifiers? enum_declaration[$modifiers.st])
    | ^(DELEGATE attributes? modifiers? delegate_declaration)
    | ^(CONVERSION_OPERATOR attributes? modifiers? conversion_operator_declaration)
    | ^(CONSTRUCTOR attributes? modifiers? constructor_declaration)
    | ^(DESTRUCTOR attributes? modifiers? destructor_declaration)
    ;

// class_member_declaration:
// 	attributes?
// 	m=modifiers?
// 	( 'const'   t1=type   constant_declarators   ';'
// 	| event_declaration		// 'event'
// 	| 'partial' (method_declaration 
// 			   | interface_declaration[$m.st] 
// 			   | class_declaration[$m.st] 
// 			   | struct_declaration)
// 	| interface_declaration[$m.st]	// 'interface'
// //	| 'void'   method_declaration
// 	| t2=type ( (member_name   '(') => method_declaration
// 		   | (member_name   '{') => property_declaration
// 		   | (member_name   '.'   'this') => type_name '.' indexer_declaration
// 		   | indexer_declaration	//this
// 	       | field_declaration     -> field(modifiers={$m.st}, type={$t2.st}, field={$field_declaration.st}) // qid
// 	       | operator_declaration
// 	       )
// //	common_modifiers// (method_modifiers | field_modifiers)
// 	
// 	| c2=class_declaration[$m.st] -> { $c2.st }		// 'class'
// 	| s2=struct_declaration	-> { $s2.st }// 'struct'	   
// 	| e2=enum_declaration[$m.st]	-> { $e2.st }	// 'enum'
// 	| delegate_declaration	// 'delegate'
// 	| conversion_operator_declaration
// 	| constructor_declaration	//	| static_constructor_declaration
// 	| destructor_declaration
// 	) 
// 	;
// 
primary_expression: 
    ^(INDEX expression expression_list?)
    | ^(APPLY expression argument_list?)
    | ^(POSTINC expression)
    | ^(POSTDEC expression)
    | primary_expression_start -> { $primary_expression_start.st }
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
// primary_expression: 
// 	('this'    brackets) => 'this'   brackets   primary_expression_part*
// 	| ('base'   brackets) => 'this'   brackets   primary_expression_part*
// 	| primary_expression_start   pp+=primary_expression_part* -> primary_expression_start_parts(start={ $primary_expression_start.st }, follows={ $pp })
// 	| 'new' (   (object_creation_expression   ('.'|'->'|'[')) => 
// 					object_creation_expression   primary_expression_part+ 		// new Foo(arg, arg).Member
// 				// try the simple one first, this has no argS and no expressions
// 				// symantically could be object creation
// 				| (delegate_creation_expression) => delegate_creation_expression// new FooDelegate (MyFunction)
// 				| object_creation_expression
// 				| anonymous_object_creation_expression)							// new {int X, string Y} 
// 	| sizeof_expression						// sizeof (struct)
// 	| checked_expression            		// checked (...
// 	| unchecked_expression          		// unchecked {...}
// 	| default_value_expression      		// default
// 	| anonymous_method_expression			// delegate (int foo) {}
// 	;

primary_expression_start:
	predefined_type            
	| (identifier    generic_argument_list) => identifier   generic_argument_list
	| identifier ('::'   identifier)?
	| 'this' 
	| 'base'
	| ^(TEMPPARENS expression) -> template(e={$expression.st}) "(<e>)" 
	| typeof_expression             // typeof(Foo).Name
	| literal -> { $literal.st }
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
	rs+=rank_specifier+ -> template(rs={$rs}) "<rs>";        
rank_specifier: 
	'['  /* dim_separators? */   ']' -> string(payload={"[]"}) ;
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
	(array_creation_expression) => array_creation_expression -> { $array_creation_expression.st } 
	| primary_expression -> { $primary_expression.st } 
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
	expression	-> { $expression.st } | array_initializer -> { $array_initializer.st };
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
	namespace_or_type_name -> { $namespace_or_type_name.st };
namespace_or_type_name:
	 t1=type_or_generic -> { $t1.st }
    | ^('::' n2=namespace_or_type_name t2=type_or_generic) -> template(ns={ $n2.st }, tg={ $t2.st }) "<ns>::<tg>"
    | ^('.'  n3=namespace_or_type_name t3=type_or_generic)  -> template(ns={ $n3.st }, tg={ $t3.st }) "<ns>.<tg>";

//	 t1=type_or_generic   ('::' t2=type_or_generic)? ('.'   ts+=type_or_generic)* -> namespace_or_type(type1={$t1.st}, type2={$t2.st}, types={$ts});
type_or_generic:
	(identifier   generic_argument_list) => gi=identifier   generic_argument_list -> template(name={ $gi.st }, args={ $generic_argument_list.st }) "<name><args>"
	| i=identifier -> { $i.st };

qid:		// qualified_identifier v2
    ^(access_operator qd=qid type_or_generic) -> template(op={ $access_operator.st }, start = { $qd.st}, end = { $type_or_generic.st }) "<start><op><end>"
	| qid_start  -> { $qid_start.st }
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
	'<'   type_arguments   '>' -> template(args={ $type_arguments.st }) "\<<args>\>";
type_arguments:
	ts+=type (',' ts+=type)* -> template(types = { $ts }) "<types; separator=\",\">";

type
@init {
    StringTemplate nm = null;
    List<string> stars = new List<string>();
    string opt = null;
}:
	  ^(TYPE (tp=predefined_type {nm=$tp.st;} | tn=type_name {nm=$tn.st;} | tv='void' {nm=new StringTemplate("void");})  rank_specifiers? ('*' { stars.Add("*");})* ('?' { opt = "?";} )?)  ->  type(name={ nm }, stars={ stars }, rs={ $rank_specifiers.st }, opt={ opt })
	;
non_nullable_type:
	type -> { $type.st } ;
	
non_array_type:
	type -> { $type.st } ;
array_type:
	type -> { $type.st } ;
unmanaged_type:
	type -> { $type.st } ;
class_type:
	type -> { $type.st } ;
pointer_type:
	type -> { $type.st } ;


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
	| non_assignment_expression -> { $non_assignment_expression.st }
	;
expression_list:
	expression  (','   expression)* ;
assignment:
	unary_expression   assignment_operator   expression ;
unary_expression: 
	//('(' arguments ')' ('[' | '.' | '(')) => primary_or_array_creation_expression
//	^(CAST_EXPR type expression) 
	^(CAST_EXPR type u0=unary_expression)  -> cast_expr(type= { $type.st}, exp = { $u0.st})
	| primary_or_array_creation_expression -> { $primary_or_array_creation_expression.st }
	| ^(MONOPLUS u1=unary_expression) -> template(e={$u1.st}) "+<e>"
	| ^(MONOMINUS u2=unary_expression) -> template(e={$u2.st}) "-<e>"
	| ^(MONONOT u3=unary_expression) -> template(e={$u3.st}) "!<e>"
	| ^(MONOTWIDDLE u4=unary_expression) -> template(e={$u4.st}) "~<e>"
	| ^(PREINC u5=unary_expression) -> template(e={$u5.st}) "++<e>"
	| ^(PREDEC u6=unary_expression) -> template(e={$u6.st}) "--<e>"
	| ^(MONOSTAR unary_expression) 
	| ^(ADDRESSOF unary_expression)
    ;
    
// 	(cast_expression) => cast_expression 
// 	| primary_or_array_creation_expression -> { $primary_or_array_creation_expression.st }
// 	| '+'   u1=unary_expression -> template(e={$u1.st}) "+<e>"
// 	| '-'   u2=unary_expression  -> template(e={$u2.st}) "-<e>"
// 	| '!'   u3=unary_expression  -> template(e={$u3.st}) "!<e>"
// 	| '~'   u4=unary_expression  -> template(e={$u4.st}) "~<e>"
// 	| pre_increment_expression 
// 	| pre_decrement_expression 
// 	| pointer_indirection_expression
// 	| addressof_expression 
// 	;
// cast_expression:
// 	^(CAST_EXPR  type unary_expression ) -> cast_expr(type= { $type.st}, exp = { $unary_expression.st});
 assignment_operator:
	'=' | '+=' | '-=' | '*=' | '/=' | '%=' | '&=' | '|=' | '^=' | '<<=' | '>' '>=' ;
// pre_increment_expression: 
// 	'++'   unary_expression ;
// pre_decrement_expression: 
// 	'--'   unary_expression ;
// pointer_indirection_expression:
// 	'*'   unary_expression ;
// addressof_expression:
// 	'&'   unary_expression ;

non_assignment_expression:
	//'non ASSIGNment'
	(anonymous_function_signature   '=>')	=> lambda_expression
	| (query_expression) => query_expression 
	| ^(COND_EXPR non_assignment_expression non_assignment_expression non_assignment_expression) 
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
    | unary_expression -> { $unary_expression.st }
	;

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

class_declaration[StringTemplate modifiersST]
@init {
    List<string> preComments = null;
}:
   ^(c=CLASS { preComments = CollectedComments; } 
            identifier type_parameter_constraints_clauses? type_parameter_list[$type_parameter_constraints_clauses.tpConstraints]?
         class_extends? class_implements? class_body )
    -> class(modifiers = {modifiersST}, name={ $identifier.st }, typeparams= {$type_parameter_list.st}, comments = { preComments },
            extends = { $class_extends.st }, imps = { $class_implements.st }, body={$class_body.st}) ;

type_parameter_list [Dictionary<string,StringTemplate> tpConstraints]:
    (attributes? t+=type_parameter[tpConstraints])+ -> template(params={ $t }) "\<<params; separator=\",\">\>";

type_parameter [Dictionary<string,StringTemplate> tpConstraints]
@init {
    StringTemplate mySt = null; 
}:
    identifier {if (tpConstraints == null || !tpConstraints.TryGetValue($identifier.text, out mySt)) {mySt = $identifier.st;}; } -> { mySt } ;

class_extends:
	^(EXTENDS ts+=type*) -> extends(types = { $ts }) ;
class_implements:
	^(IMPLEMENTS ts+=type*) -> imps(types = { $ts }) ;
	
interface_type_list:
	ts+=type (','   ts+=type)* -> template(types={ $ts }) "<types; separator=\",\">";

class_body:
	'{'   cs+=class_member_declaration_aux*   '}' -> class_body(entries={$cs}) ;
class_member_declaration_aux
@init{
    List<string> preComments = null;
}:
    { preComments = CollectedComments; } member=class_member_declaration -> class_member(comments={ preComments }, member={ $member.st }) ;


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
	variable_declarators   ';'	-> { $variable_declarators.st };
variable_declarators:
	vs+=variable_declarator (','   vs+=variable_declarator)* -> variable_declarators(varinits = {$vs});
variable_declarator:
	type_name ('='   variable_initializer)? -> variable_declarator(typename = { $type_name.st }, init = { $variable_initializer.st}) ;		// eg. event EventHandler IInterface.VariableName = Foo;

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
enum_declaration[StringTemplate modifiersST]
@init {
    List<string> preComments = null;
}:
	e='enum' { preComments = CollectedComments; }  identifier   enum_base?   enum_body   ';'?
    -> enum(comments = { preComments}, modifiers = { $modifiersST }, name={$identifier.text}, body={$enum_body.st}) ;
enum_base:
	':'   integral_type ;
enum_body:
	^(ENUM_BODY es+=enum_member_declaration+) -> enum_body(values={$es});
enum_member_declaration:
	attributes?   identifier -> enum_member(comments = { CollectedComments }, value={ $identifier.st });
//enum_modifiers:
//	enum_modifier+ ;
//enum_modifier:
//	'new' | 'public' | 'protected' | 'internal' | 'private' ;
integral_type: 
	'sbyte' | 'byte' | 'short' | 'ushort' | 'int' | 'uint' | 'long' | 'ulong' | 'char' ;

// B.2.12 Delegates
delegate_declaration:
	'delegate'   return_type   identifier  type_parameter_constraints_clauses? variant_generic_parameter_list[$type_parameter_constraints_clauses.tpConstraints]?   
		'('   formal_parameter_list?   ')'      ';' ;
delegate_modifiers:
	modifier+ ;
// 4.0
variant_generic_parameter_list [Dictionary<string,StringTemplate> tpConstraints]:
	(ps+=variant_generic_parameter[$tpConstraints])+ -> template(params={$ps}) "<params; separator=\",\">";
variant_generic_parameter [Dictionary<string,StringTemplate> tpConstraints]:
    attributes?   variance_annotation?  t=type_parameter[$tpConstraints] ->  template(param={$t.st}, annotation={$variance_annotation.st}) "/* <annotation> */ <param>" ;
variance_annotation:
	IN -> template() "in" | OUT -> template() "out" ;

// tpConstraints is a map from type variable name to a string expressing the extends constraints
type_parameter_constraints_clauses returns [Dictionary<string,StringTemplate> tpConstraints]
@init {
    $tpConstraints = new Dictionary<string,StringTemplate>();
}
:
	ts+=type_parameter_constraints_clause[$tpConstraints]+ -> ;
type_parameter_constraints_clause [Dictionary<string,StringTemplate> tpConstraints]
@after{
    tpConstraints[$t.text] = $type_parameter_constraints_clause.st;
}:
    ^(TYPE_PARAM_CONSTRAINT t=type_variable_name ts+=type_name+) -> type_param_constraint(param= { $type_variable_name.st }, constraints = { $ts }) ;
type_variable_name: 
	identifier -> { $identifier.st } ;
// keving: stripped
//constructor_constraint:
//	'new'   '('   ')' ;
return_type:
	type -> { $type.st } ;
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
interface_declaration[StringTemplate modifiersST]
@init {
    List<string> preComments = null;
}:
   ^(c=INTERFACE { preComments = CollectedComments; } 
            identifier  type_parameter_constraints_clauses?  variant_generic_parameter_list[$type_parameter_constraints_clauses.tpConstraints]?
         class_extends?   interface_body )
    -> iface(modifiers = {modifiersST}, name={ $identifier.st }, typeparams={$variant_generic_parameter_list.st} ,comments = { preComments },
            imps = { $class_extends.st }) ;
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
			   | interface_declaration[$m.st] 
			   | class_declaration[$m.st] 
			   | struct_declaration)

	| interface_declaration[$m.st]	// 'interface'
	| class_declaration[$m.st]		// 'class'
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
	| enum_declaration[$m.st]		// 'enum'
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

// keving: split statement into two parts, there seems to be a problem with the state
// machine if we combine statement and statement_plus.
statement:
	(declaration_statement) => declaration_statement
	| statement_plus
	;
statement_plus:
	(identifier   ':') => labeled_statement
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
	| type  -> { $type.st } ;
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
	  (t='bool' | t='byte'   | t='char'   | t='decimal' | t='double' | t='float'  | t='int'    | t='long'   | t='object' | t='sbyte'  
	| t='short'  | t='string' | t='uint'   | t='ulong'  | t='ushort') ->  string(payload={$t.text});

identifier:
 	i=IDENTIFIER { collectComments($i.TokenStartIndex); } -> template(v= { $IDENTIFIER.text }) "<v>" | also_keyword -> template(v= { $also_keyword.text }) "<v>";

keyword:
	'abstract' | 'as' | 'base' | 'bool' | 'break' | 'byte' | 'case' |  'catch' | 'char' | 'checked' | 'class' | 'const' | 'continue' | 'decimal' | 'default' | 'delegate' | 'do' |	'double' | 'else' |	 'enum'  | 'event' | 'explicit' | 'extern' | 'false' | 'finally' | 'fixed' | 'float' | 'for' | 'foreach' | 'goto' | 'if' | 'implicit' | 'in' | 'int' | 'interface' | 'internal' | 'is' | 'lock' | 'long' | 'namespace' | 'new' | 'null' | 'object' | 'operator' | 'out' | 'override' | 'params' | 'private' | 'protected' | 'public' | 'readonly' | 'ref' | 'return' | 'sbyte' | 'sealed' | 'short' | 'sizeof' | 'stackalloc' | 'static' | 'string' | 'struct' | 'switch' | 'this' | 'throw' | 'true' | 'try' | 'typeof' | 'uint' | 'ulong' | 'unchecked' | 'unsafe' | 'ushort' | 'using' | 'virtual' | 'void' | 'volatile' ;

also_keyword:
	'add' | 'alias' | 'assembly' | 'module' | 'field' | 'method' | 'param' | 'property' | 'type' | 'yield'
	| 'from' | 'into' | 'join' | 'on' | 'where' | 'orderby' | 'group' | 'by' | 'ascending' | 'descending' 
	| 'equals' | 'select' | 'pragma' | 'let' | 'remove' | 'get' | 'set' | 'var' | '__arglist' | 'dynamic' | 'elif' 
	| 'endif' | 'define' | 'undef';

literal:
	Real_literal -> string(payload={$Real_literal.text}) 
	| NUMBER -> string(payload={$NUMBER.text}) 
	| Hex_number -> string(payload={$Hex_number.text}) 
	| Character_literal -> string(payload={$Character_literal.text}) 
	| STRINGLITERAL -> string(payload={ $STRINGLITERAL.text }) 
	| Verbatim_string_literal -> string(payload={ "\"" + escapeJavaString($Verbatim_string_literal.text.Substring(1)) + "\"" }) 
	| TRUE -> string(payload={"true"}) 
	| FALSE -> string(payload={"false"}) 
	| NULL -> string(payload={"null"}) 
	;

