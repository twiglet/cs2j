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
        CollectedComments = rets;
    }

    protected void collectComments() {
        collectComments(((CommonTokenStream)this.GetTreeNodeStream().TokenStream).GetTokens().Count - 1);
    }

    protected List<string> escapeJavaString(string rawStr)
    {
        List<string> rets = new List<string>();
        StringBuilder buf = new StringBuilder();
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
                rets.Add(buf.ToString());
                buf = new StringBuilder();
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
        if (buf.Length > 0) {
           rets.Add(buf.ToString());
        }
        return rets;
    }

    // keving:  Found this precedence table on the ANTLR site.
    
    /** Encodes precedence of various operators; indexed by token type.
     *  If precedence[op1] > precedence[op2] then op1 should happen
     *  before op2;
     * table from http://www.cs.princeton.edu/introcs/11precedence/ 
     */
    private int[] precedence = new int[tokenNames.Length];
    private bool precedenceInitted = false;
    protected bool IsPrecedenceInitted {
        get { return precedenceInitted; }
        set { precedenceInitted = value; }
    }
    private void initPrecedence()
    {
        if (IsPrecedenceInitted) 
            return;

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
        precedence[RIGHT_SHIFT_ASSIGN] = 1;
        precedence[LEFT_SHIFT_ASSIGN] = 1;
        precedence[UNSIGNED_RIGHT_SHIFT_ASSIGN] = 1;
        precedence[BIT_AND_ASSIGN] =1;
        precedence[BIT_XOR_ASSIGN] = 1;
        precedence[BIT_OR_ASSIGN] = 1;

        precedence[COND_EXPR] = 2;

        precedence[LOG_OR] = 3;

        precedence[LOG_AND] = 4;

        precedence[BIT_OR] = 5;

        precedence[BIT_XOR] = 6;

        precedence[BIT_AND] = 7;

        precedence[NOT_EQUAL] = 8;
        precedence[EQUAL] = 8;

        precedence[LTHAN] = 9;
        precedence[GT] = 9;
        precedence[LTE] = 9;
        precedence[GTE] = 9;
        precedence[INSTANCEOF] = 9;
        
        precedence[LEFT_SHIFT] = 10;
        precedence[RIGHT_SHIFT] = 10;
        precedence[UNSIGNED_RIGHT_SHIFT] = 10;

        precedence[PLUS] = 11;
        precedence[MINUS] = 11;
 
        precedence[DIV] = 12;
        precedence[MOD] = 12;
        precedence[STAR] = 12;
         
        precedence[CAST_EXPR] = 13;
        precedence[NEW] = 13;
 
        precedence[PREINC] = 14;
        precedence[PREDEC] = 14;
        precedence[MONONOT] = 14;
        precedence[MONOTWIDDLE] = 14;
        precedence[MONOMINUS] = 14;
        precedence[MONOPLUS] = 14;
 
        precedence[POSTINC] = 15;
        precedence[POSTDEC] = 15;   
        precedence[APPLY] = 16;   
        precedence[INDEX] = 16;   
        precedence[DOT] = 16;   

        IsPrecedenceInitted = true;
     }


    // Compares precedence of op1 and op2. 
    // Returns -1 if op2 < op1
    //	        0 if op1 == op2
    //          1 if op2 > op1
    public int comparePrecedence(IToken op1, IToken op2) {
        return Math.Sign(precedence[op2.Type]-precedence[op1.Type]);
    }
    public int comparePrecedence(IToken op1, int childPrec) {
        return Math.Sign(childPrec-precedence[op1.Type]);
    }
    public int comparePrecedence(int parentPrec, int childPrec) {
        return Math.Sign(childPrec-parentPrec);
    }
}

compilation_unit
@init{
    initPrecedence();
    // Print all tokens
    //for (int i = 0; i < TokenNames.Length; i++) {
    //    Console.Out.WriteLine("{0}  ->  {1}", TokenNames[i], i);
    //}
}
:
    ^(PACKAGE nm=PAYLOAD modifiers? type_declaration[$modifiers.st] { if (IsLast) collectComments(); }) -> 
        package(now = {DateTime.Now}, includeDate = {Cfg.TranslatorAddTimeStamp}, packageName = {($nm.text != null && $nm.text.Length > 0 ? $nm.text : null)}, 
            type = {$type_declaration.st},
            endComments = { CollectedComments });

type_declaration [StringTemplate modifiersST]:
    class_declaration[modifiersST] -> { $class_declaration.st }
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
@init {
    String thetext = null;
}
: 
        (m='new' | m='public' | m='protected' | m='private' | m='abstract' | m='sealed' | m='static'
        | m='readonly' | m='volatile' | m='extern' { thetext = "/* [UNSUPPORTED] 'extern' modifier not supported */"; } | m='virtual' | m='override' | m=FINAL)
        -> string(payload={ (thetext == null ? $m.text : thetext) });
	
class_member_declaration returns [List<String> preComments]:
    ^(CONST attributes? modifiers? type { $preComments = CollectedComments; } constant_declarators)
    | ^(EVENT attributes? modifiers? { $preComments = CollectedComments; } event_declaration)
    | ^(METHOD attributes? modifiers? type member_name type_parameter_constraints_clauses? type_parameter_list[$type_parameter_constraints_clauses.tpConstraints]? formal_parameter_list?
            { $preComments = CollectedComments; } method_body exception*)
      -> method(modifiers={$modifiers.st}, type={$type.st}, name={ $member_name.st }, typeparams = { $type_parameter_list.st }, params={ $formal_parameter_list.st }, exceptions = { $exception.st }, bodyIsSemi = { $method_body.isSemi }, body={ $method_body.st })
//    | ^(METHOD attributes? modifiers? type method_declaration)     -> method(modifiers={$modifiers.st}, type={$type.st}, method={$method_declaration.st}) 
    | ^(INTERFACE attributes? modifiers? interface_declaration[$modifiers.st]) -> { $interface_declaration.st }
    | ^(CLASS attributes? modifiers? class_declaration[$modifiers.st]) -> { $class_declaration.st }
    | ^(INDEXER attributes? modifiers? type type_name? { $preComments = CollectedComments; } indexer_declaration)
    | ^(FIELD attributes? modifiers? type { $preComments = CollectedComments; } field_declaration)  -> field(modifiers={$modifiers.st}, type={$type.st}, field={$field_declaration.st}) 
    | ^(OPERATOR attributes? modifiers? type { $preComments = CollectedComments; } operator_declaration)
    | ^(ENUM attributes? modifiers? { $preComments = CollectedComments; } enum_declaration[$modifiers.st])
    | ^(DELEGATE attributes? modifiers? { $preComments = CollectedComments; } delegate_declaration)
    | ^(CONVERSION_OPERATOR attributes? modifiers? conversion_operator_declaration)
    | ^(CONSTRUCTOR attributes? modifiers? identifier  formal_parameter_list?  { $preComments = CollectedComments; } block exception*)
       -> constructor(modifiers={$modifiers.st}, name={ $identifier.st }, params={ $formal_parameter_list.st }, exceptions = { $exception.st}, bodyIsSemi = { $block.isSemi }, body={ $block.st })
    | ^(STATIC_CONSTRUCTOR attributes? modifiers? block)
       -> static_constructor(modifiers={$modifiers.st}, bodyIsSemi = { $block.isSemi }, body={ $block.st })
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

exception:
    EXCEPTION -> string(payload = { $EXCEPTION.text });

primary_expression returns [int precedence]
@init {
    $precedence = int.MaxValue;
}: 
    ^(INDEX expression expression_list?) { $precedence = precedence[INDEX]; } -> index(func= { $expression.st }, funcparens = { comparePrecedence(precedence[INDEX], $expression.precedence) < 0 }, args = { $expression_list.st } )
    | ^(APPLY expression argument_list?) { $precedence = precedence[APPLY]; } -> application(func= { $expression.st }, funcparens = { comparePrecedence(precedence[APPLY], $expression.precedence) < 0 }, args = { $argument_list.st } )
    | ^((op=POSTINC|op=POSTDEC) expression) { $precedence = precedence[$op.token.Type]; } 
         -> op(pre={$expression.st}, op={ $op.token.Text }, preparens= { comparePrecedence($op.token, $expression.precedence) <= 0 })
    | primary_expression_start -> { $primary_expression_start.st }
    | ^(access_operator expression identifier generic_argument_list?) { $precedence = $access_operator.precedence; } 
       -> member_access(pre={ $expression.st }, op={ $access_operator.st }, access={ $identifier.st }, access_tyargs = { $generic_argument_list.st },
              preparen = { comparePrecedence($access_operator.precedence, $expression.precedence) < 0 })
//     | ^(access_operator expression SEP identifier) { $precedence = $access_operator.precedence; } 
//        -> op(pre={ $expression.st }, op={ $access_operator.st }, post={ $identifier.st },
//               preparen = { comparePrecedence($access_operator.precedence, $expression.precedence) < 0 })
//	('this'    brackets) => 'this'   brackets   primary_expression_part*
//	| ('base'   brackets) => 'this'   brackets   primary_expression_part*
//	| primary_expression_start   primary_expression_part*
    | ^(NEW type argument_list? object_or_collection_initializer?) { $precedence = precedence[NEW]; }-> construct(type = {$type.st}, args = {$argument_list.st}, inits = {$object_or_collection_initializer.st})
	| 'new' (   
				// try the simple one first, this has no argS and no expressions
				// symantically could be object creation
				 (delegate_creation_expression) => delegate_creation_expression// new FooDelegate (MyFunction)
				| object_creation_expression
				| anonymous_object_creation_expression)							// new {int X, string Y} 
	| sizeof_expression						// sizeof (struct)
	| checked_expression      -> { $checked_expression.st }      		// checked (...
	| unchecked_expression     -> { $unchecked_expression.st }     		// unchecked {...}
	| default_value_expression  -> { $default_value_expression.st }    		// default
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
	predefined_type    -> { $predefined_type.st }        
	| (identifier    generic_argument_list) => identifier   generic_argument_list -> op(pre={ $identifier.st }, post={ $generic_argument_list.st})
	| i1=identifier -> { $i1.st } 
	| primary_expression_extalias -> unsupported(reason = {"external aliases are not yet supported"}, text= { $primary_expression_extalias.st } ) 
	| 'this' -> string(payload = { "this" }) 
	| SUPER-> string(payload = { "super" }) 
    // keving: needs fixing in javamaker - > type.class
	| ^('typeof'  unbound_type_name ) -> typeof(type= { $unbound_type_name.st })
	| ^('typeof'  type ) -> typeof(type= { $type.st })
	| literal -> { $literal.st }
	;

primary_expression_extalias:
	i1=identifier '::'   i2=identifier -> op(pre={ $i1.st }, op = { "::" }, post={ $i2.st }) 
    ;


primary_expression_part:
	 access_identifier
	| brackets_or_arguments 
	| '++'
	| '--' ;
access_identifier:
	access_operator   type_or_generic ;
access_operator returns [int precedence]:
	(op='.'  |  op='->') { $precedence = precedence[$op.token.Type]; } -> string(payload = { $op.token.Text }) ;
brackets_or_arguments:
	brackets | arguments ;
brackets:
	'['   expression_list?   ']' ;	
paren_expression:	
	'('   expression   ')' ;
arguments: 
	'('   argument_list?   ')' ;
argument_list: 
	^(ARGS args+=argument+) -> list(items= {$args}, sep={", "});
// 4.0
argument:
	argument_name   argument_value
	| argument_value -> { $argument_value.st };
argument_name:
	argument_name_unsupported -> unsupported(reason={ "named parameters are not yet supported"}, text = { $argument_name_unsupported.st } );
argument_name_unsupported:
	identifier   ':' -> op(pre={$identifier.st}, op={":"});
argument_value
@init {
    StringTemplate someText = null;
}: 
	expression -> { $expression.st }
	| ref_variable_reference 
	| 'out'   variable_reference 
        { someText = %op(); 
          %{someText}.op = "out"; 
          %{someText}.post = $variable_reference.st; 
          %{someText}.space = " ";
        } ->  unsupported(reason = {"out arguments are not yet supported"}, text = { someText } )
     ;
ref_variable_reference:
	'ref' 
		(('('   type   ')') =>   '('   type   ')'   (ref_variable_reference | variable_reference)   // SomeFunc(ref (int) ref foo)
																									// SomeFunc(ref (int) foo)
		| variable_reference);	// SomeFunc(ref foo)
// lvalue
variable_reference:
	expression -> { $expression.st };
rank_specifiers: 
	rs+=rank_specifier+ -> rank_specifiers(rs={$rs});        
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
primary_or_array_creation_expression returns [int precedence]:
	(array_creation_expression) => array_creation_expression { $precedence = $array_creation_expression.precedence; }  -> { $array_creation_expression.st } 
	| primary_expression { $precedence = $primary_expression.precedence; } -> { $primary_expression.st } 
	;
// new Type[2] { }
array_creation_expression returns [int precedence]:
	^('new'   
		(type   ('['   expression_list   ']'   
					( rank_specifiers?   ai1=array_initializer?	 -> array_construct(type = { $type.st }, args = { $expression_list.st }, inits = { $ai1.st })  // new int[4]
					// | invocation_part*
					| ( ((arguments   ('['|'.'|'->')) => arguments   invocation_part)// new object[2].GetEnumerator()
					  | invocation_part)*   arguments
					)							// new int[4]()
				| ai2=array_initializer	-> 	array_construct(type = { $type.st }, inits = { $ai2.st })
				)
		| rank_specifier   // [,]
			(array_initializer	// var a = new[] { 1, 10, 100, 1000 }; // int[]
		    )
		)) { $precedence = precedence[NEW]; };
array_initializer:
	'{'   variable_initializer_list?   ','?   '}' -> array_initializer(init = { $variable_initializer_list.st });
variable_initializer_list:
	vs+=variable_initializer (',' vs+=variable_initializer)* -> seplist(items = { $vs }, sep = {", "});
variable_initializer:
	expression	-> { $expression.st } | array_initializer -> { $array_initializer.st };
sizeof_expression:
	^('sizeof'  unmanaged_type );
checked_expression
@init {
    StringTemplate someText = null;
}: 
	^('checked' expression ) 
        { someText = %op(); 
          %{someText}.op = "checked"; 
          %{someText}.post = $expression.st; 
          %{someText}.space = " ";
        } ->  unsupported(reason = {"checked expressions are not supported"}, text = { someText } )
;
unchecked_expression
@init {
    StringTemplate someText = null;
}: 
	^('unchecked' expression ) 
        { someText = %op(); 
          %{someText}.op = "unchecked"; 
          %{someText}.post = $expression.st; 
          %{someText}.space = " ";
        } ->  unsupported(reason = {"unchecked expressions are not supported"}, text = { someText } )
;
default_value_expression
@init {
    StringTemplate someText = null;
}: 
	^('default' type   ) 
        { someText = %op(); 
          %{someText}.op = "default"; 
          %{someText}.post = $type.st; 
          %{someText}.space = " ";
        } ->  unsupported(reason = {"default expressions are not yet supported"}, text = { someText } )
;
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
        // keving: external aliases not supported
    | ^('::' n2=namespace_or_type_name t2=type_or_generic) -> { $t2.st }
    | ^(op='.'  n3=namespace_or_type_name t3=type_or_generic)  -> op(pre={ $n3.st }, op = { "." }, post={ $t3.st });

//	 t1=type_or_generic   ('::' t2=type_or_generic)? ('.'   ts+=type_or_generic)* -> namespace_or_type(type1={$t1.st}, type2={$t2.st}, types={$ts});
type_or_generic returns [int precedence]
@init {
    $precedence = int.MaxValue;
}:
	(identifier   generic_argument_list) => gi=identifier   generic_argument_list -> op(pre={ $gi.st }, post={ $generic_argument_list.st })
	| i=identifier -> { $i.st };

qid:		// qualified_identifier v2
    ^(access_operator qd=qid type_or_generic) -> op(op={ $access_operator.st }, pre = { $qd.st}, post = { $type_or_generic.st })
	| qid_start  -> { $qid_start.st }
	;
qid_start:
	predefined_type -> { $predefined_type.st }
	| (identifier   generic_argument_list)	=> identifier   generic_argument_list -> op(pre={ $identifier.st }, post={ $generic_argument_list.st })
//	| 'this'
//	| 'base'
	| i1=identifier   ('::'   i2=identifier)?  -> identifier(id={ $i1.st }, id2={ $i2.st })
	| literal -> { $literal.st }
	;		// 0.ToString() is legal


qid_part:
	access_identifier ;

generic_argument_list:
	'<'   type_arguments   '>' -> generic_args(args={ $type_arguments.st });
type_arguments:
	ts+=type (',' ts+=type)* -> commalist(items = { $ts });

type
@init {
    StringTemplate nm = null;
    List<string> stars = new List<string>();
    string opt = null;
}:
	  ^(TYPE (tp=predefined_type {nm=$tp.st;} | tn=type_name {nm=$tn.st;} | tv='void' { nm=%void();})  rank_specifiers? ('*' { stars.Add("*");})* ('?' { opt = "?";} )?)  ->  type(name={ nm }, stars={ stars }, rs={ $rank_specifiers.st }, opt={ opt })
	;
non_nullable_type:
	type -> { $type.st } ;
	
non_array_type:
	type -> { $type.st } ;
array_type:
	type -> { $type.st } ;
unmanaged_type:
	type -> { $type.st } ;
pointer_type:
	type -> { $type.st } ;


///////////////////////////////////////////////////////
//	Statement Section
///////////////////////////////////////////////////////
block returns [bool isSemi]
@init {
    $isSemi = false;
}:
	';' { $isSemi = true; } -> string(payload = { "    ;" }) 
	| '{'   s+=statement*   '}' -> braceblock(statements = { $s });

///////////////////////////////////////////////////////
//	Expression Section
///////////////////////////////////////////////////////	
expression returns [int precedence]: 
	(unary_expression   assignment_operator) => assignment { $precedence = $assignment.precedence; } -> { $assignment.st }
	| non_assignment_expression { $precedence = $non_assignment_expression.precedence; } -> { $non_assignment_expression.st }
	;
expression_list:
	e+=expression  (','   e+=expression)* -> list(items= { $e }, sep = {", "});
assignment returns [int precedence]:
	unary_expression   assignment_operator   expression { $precedence = $assignment_operator.precedence; }
                                                         -> assign(lhs={ $unary_expression.st }, assign = { $assignment_operator.st }, rhs = { $expression.st }, 
                                                                    lhsparen={ comparePrecedence($assignment_operator.precedence, $unary_expression.precedence) <= 0 },
                                                                     rhsparen={ comparePrecedence($assignment_operator.precedence, $expression.precedence) < 0});
unary_expression returns [int precedence]
@init {
    // By default parens not needed
    $precedence = int.MaxValue;
}: 
	//('(' arguments ')' ('[' | '.' | '(')) => primary_or_array_creation_expression
//	^(CAST_EXPR type expression) 
	^(CAST_EXPR type u0=unary_expression)  { $precedence = precedence[CAST_EXPR]; } -> cast_expr(type= { $type.st}, exp = { $u0.st})
	| primary_or_array_creation_expression { $precedence = $primary_or_array_creation_expression.precedence; } -> { $primary_or_array_creation_expression.st }
	| ^((op=MONOPLUS | op=MONOMINUS | op=MONONOT | op=MONOTWIDDLE | op=PREINC | op=PREDEC)  u1=unary_expression) { $precedence = precedence[$op.token.Type]; }
          -> op(postparen={ comparePrecedence($op.token, $u1.precedence) <= 0 }, op={ $op.token.Text }, post={$u1.st})
	| ^((op=MONOSTAR|op=ADDRESSOF) u1=unary_expression) 
        { 
            StringTemplate opText = %op();
            %{opText}.post = $u1.st;
            %{opText}.op = $op.token.Text;
            $st = %unsupported();
            %{$st}.reason = "the " + ($op.token.Type == MONOSTAR ? "pointer indirection" : "address of") + " operator is not supported";
            %{$st}.text = opText;
        }
      // PARENS is not strictly necessary because we insert parens where necessary. However
      // we maintain parens inserted by original programmer since, presumably, they 
      // improve understandability
	| ^(PARENS expression) { $precedence = Cfg.TranslatorKeepParens ? int.MaxValue : $expression.precedence; } 
                           -> { Cfg.TranslatorKeepParens}? parens(e={$expression.st}) 
                           -> {$expression.st} 
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
 assignment_operator returns [int precedence]: 
   (op='=' | op='+=' | op='-=' | op='*=' | op='/=' | op='%=' | op='&=' | op='|=' | op='^=' | op='<<=' | op=RIGHT_SHIFT_ASSIGN) { $precedence = precedence[$op.token.Type]; } 
      -> string(payload = { $op.token.Text });
// pre_increment_expression: 
// 	'++'   unary_expression ;
// pre_decrement_expression: 
// 	'--'   unary_expression ;
// pointer_indirection_expression:
// 	'*'   unary_expression ;
// addressof_expression:
// 	'&'   unary_expression ;

non_assignment_expression returns [int precedence]
@init {
    // By default parens not needed
    $precedence = int.MaxValue;
}: 
	//'non ASSIGNment'
	(anonymous_function_signature   '=>')	=> lambda_expression
	| (query_expression) => query_expression 
	| ^(cop=COND_EXPR ce1=non_assignment_expression ce2=non_assignment_expression ce3=non_assignment_expression) { $precedence = precedence[$cop.token.Type]; } 
          -> cond( condexp = { $ce1.st }, thenexp = { $ce2.st }, elseexp = { $ce3.st },
                    condparens = { comparePrecedence($cop.token, $ce1.precedence) <= 0 }, 
                    thenparens = { comparePrecedence($cop.token, $ce2.precedence) <= 0 }, 
                    elseparens = { comparePrecedence($cop.token, $ce3.precedence) <= 0 }) 
    | ^('??' non_assignment_expression non_assignment_expression)
    // All these operators have left to right associativity
    | ^((op='=='|op='!='|op='||'|op='&&'|op='|'|op='^'|op='&'|op='>'|op='<'|op='>='|op='<='|op='<<'|op='>>'|op='+'|op='-'|op='*'|op='/'|op='%') 
        e1=non_assignment_expression e2=non_assignment_expression) { $precedence = precedence[$op.token.Type]; }
         -> op(pre={ $e1.st }, op = { $op.token.Text }, post = { $e2.st }, space = { " " },
                preparen={ comparePrecedence($op.token, $e1.precedence) < 0 },
                postparen={ comparePrecedence($op.token, $e2.precedence) <= 0})
    | ^(iop=INSTANCEOF ie=non_assignment_expression non_nullable_type) { $precedence = precedence[$iop.token.Type]; } 
          -> op(pre = { $ie.st }, op = { "instanceof" }, space = { " " }, post = { $non_nullable_type.st },
                  preparen={ comparePrecedence($iop.token, $ie.precedence) < 0 })
    | unary_expression { $precedence = $unary_expression.precedence; }-> { $unary_expression.st }
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
	expression -> { $expression.st };

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
   ^(c=CLASS 
            identifier type_parameter_constraints_clauses? type_parameter_list[$type_parameter_constraints_clauses.tpConstraints]?
         class_extends? class_implements?  { preComments = CollectedComments; } class_body )
    -> class(modifiers = {modifiersST}, name={ $identifier.st }, typeparams= {$type_parameter_list.st}, comments = { preComments },
            extends = { $class_extends.st }, imps = { $class_implements.st }, body={$class_body.st}) ;

type_parameter_list [Dictionary<string,StringTemplate> tpConstraints]:
    (attributes? t+=type_parameter[tpConstraints])+ -> type_parameter_list(items={ $t });

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
	ts+=type (','   ts+=type)* -> commalist(items={ $ts });

class_body:
	'{'   cs+=class_member_declaration_aux*   '}' -> class_body(entries={$cs}) ;
class_member_declaration_aux:
    member=class_member_declaration -> class_member(comments={ $member.preComments }, member={ $member.st }) ;


///////////////////////////////////////////////////////
constant_declaration:
	'const'   type   constant_declarators   ';' ;
constant_declarators:
	constant_declarator (',' constant_declarator)* ;
constant_declarator:
	identifier   ('='   constant_expression)? ;
constant_expression:
	expression -> { $expression.st };

///////////////////////////////////////////////////////
field_declaration:
	variable_declarators	-> { $variable_declarators.st };
variable_declarators:
	vs+=variable_declarator (','   vs+=variable_declarator)* -> variable_declarators(varinits = {$vs});
variable_declarator:
	type_name ('='   variable_initializer)? -> variable_declarator(typename = { $type_name.st }, init = { $variable_initializer.st}) ;		// eg. event EventHandler IInterface.VariableName = Foo;

///////////////////////////////////////////////////////
//method_declaration:
//	method_header   method_body -> method_declaration(header={$method_header.st}, body={$method_body.st}) ;
//method_header:
//    ^(METHOD_HEADER member_name type_parameter_constraints_clauses? type_parameter_list[$type_parameter_constraints_clauses.tpConstraints]? formal_parameter_list?)
//	-> method_header(name={ $member_name.st }, typeparams = { $type_parameter_list.st }, params={ $formal_parameter_list.st });
method_body returns [bool isSemi]:
	block { $isSemi = $block.isSemi; } -> { $block.st };

member_name
@init {
    StringTemplate last_t = null;
    ArrayList pre_ts = new ArrayList();
}
:
    (type_or_generic '.') => t1=type_or_generic { last_t = $t1.st; } (op='.' tn=type_or_generic { pre_ts.Add(last_t); last_t = $tn.st; })* 
        { 
            StringTemplate interfaceText = %dotlist();
            %{interfaceText}.items = pre_ts;
            StringTemplate opText = %op();
            %{opText}.pre = interfaceText;
            %{opText}.op = $op.token.Text;
            StringTemplate unsupportedText = %unsupported();
            %{unsupportedText}.reason = "explicit interface implementation is not supported";
            %{unsupportedText}.text = opText;
            $st = %op();
            %{$st}.pre = unsupportedText;
            %{$st}.post = last_t;
            %{$st}.op = " ";
        }
    | type_or_generic -> { $type_or_generic.st }
    ;
    // keving: missing interface_type.identifier
//	identifier -> { $identifier.st };		// IInterface<int>.Method logic added.
//member_name:
//	qid -> { $qid.st };		// IInterface<int>.Method logic added.

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
	(ps+=variant_generic_parameter[$tpConstraints])+ -> commalist(items={$ps});
variant_generic_parameter [Dictionary<string,StringTemplate> tpConstraints]:
    attributes?   variance_annotation?  t=type_parameter[$tpConstraints] ->  parameter(param={$t.st}, annotation={$variance_annotation.st});
variance_annotation:
	IN -> string(payload={ "in" }) | OUT -> string(payload={ "out" }) ;

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
    ^(PARAMS fps+=formal_parameter+) -> list(items= {$fps}, sep={", "});
formal_parameter:
	attributes?   (fixed_parameter -> { $fixed_parameter.st }| parameter_array -> { $parameter_array.st }) 
	| '__arglist';	// __arglist is undocumented, see google
//fixed_parameters:
//	fps+=fixed_parameter   (','   fps+=fixed_parameter)* -> { $fps };
// 4.0
fixed_parameter:
	parameter_modifier?   type   identifier   default_argument? -> fixed_parameter(mod={ $parameter_modifier.st }, type = { $type.st }, name = { $identifier.st }, default = { $default_argument.st });
// 4.0
default_argument:
	'=' expression -> { $expression.st };
parameter_modifier:
	(m='ref' | m='out' | m='this') -> inline_comment(payload={ $m.text }, explanation={ "parameter modifiers are not yet supported" }) ;
parameter_array:
	^('params'   type   identifier) -> varargs(type={ $type.st }, name = { $identifier.st }) ;

///////////////////////////////////////////////////////
interface_declaration[StringTemplate modifiersST]
@init {
    List<string> preComments = null;
}:
   ^(c=INTERFACE 
            identifier  type_parameter_constraints_clauses?  variant_generic_parameter_list[$type_parameter_constraints_clauses.tpConstraints]?
         class_extends?   { preComments = CollectedComments; } interface_body )
    -> iface(modifiers = {modifiersST}, name={ $identifier.st }, typeparams={$variant_generic_parameter_list.st} ,comments = { preComments },
            imps = { $class_extends.st }, body = { $interface_body.st }) ;
//interface_base: 
//   	':' interface_type_list ;
interface_body:
	'{'   ms+=interface_member_declaration_aux*   '}' -> class_body(entries = { $ms });
interface_member_declaration_aux:
	member=interface_member_declaration -> class_member(comments = { $member.preComments }, member = { $member.st });

interface_member_declaration returns [List<String> preComments]:
    ^(EVENT attributes? modifiers? event_declaration)
    | ^(METHOD attributes? modifiers? type identifier type_parameter_constraints_clauses? type_parameter_list[$type_parameter_constraints_clauses.tpConstraints]? formal_parameter_list? exception*)
         { $preComments = CollectedComments; }
      -> method(modifiers={$modifiers.st}, type={$type.st}, name={ $identifier.st }, typeparams = { $type_parameter_list.st }, params={ $formal_parameter_list.st }, exceptions= { $exception.st }, bodyIsSemi = { true })
    | ^(INDEXER attributes? modifiers? type type_name? { $preComments = CollectedComments; } indexer_declaration)
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
// 			   | interface_declaration[$m.st] 
// 			   | class_declaration[$m.st] 
// 			   | struct_declaration)
// 
// 	| interface_declaration[$m.st]	// 'interface'
// 	| class_declaration[$m.st]		// 'class'
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
// 	| enum_declaration[$m.st]		// 'enum'
// 	| delegate_declaration	// 'delegate'
// 	| conversion_operator_declaration
// 	| constructor_declaration	//	| static_constructor_declaration
// 	) 
// 	;
// 

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
invocation_expression:
	invocation_start   (((arguments   ('['|'.'|'->')) => arguments   invocation_part)
						| invocation_part)*   arguments ;
invocation_start:
	predefined_type 
	| (identifier    generic_argument_list)	=> identifier   generic_argument_list
	| 'this' 
	| 'base'
	| identifier   ('::'   identifier)?
	| ^('typeof'  (unbound_type_name | type ) )             // typeof(Foo).Name
	;
invocation_part:
	 access_identifier
	| brackets ;

///////////////////////////////////////////////////////

// keving: split statement into two parts, there seems to be a problem with the state
// machine if we combine statement and statement_plus.
statement:
	(declaration_statement) => declaration_statement -> statement(statement = { $declaration_statement.st })
	| statement_plus -> statement(statement = { $statement_plus.st })
	;
statement_plus:
	(identifier   ':') => labeled_statement -> statement(statement = { $labeled_statement.st })
	| embedded_statement  -> statement(statement = { $embedded_statement.st })
	;
embedded_statement returns [bool isSemi, bool isIf, bool indent]
@init {
    StringTemplate someText = null;
    $isSemi = false;
    $isIf = false;
    $indent = true;
    List<String> preComments = null;
}:
	block { $isSemi = $block.isSemi; $indent = false; } -> { $block.st }
	| ^(IF boolean_expression { preComments = CollectedComments; } SEP  t=embedded_statement e=else_statement?) { $isIf = true; }
        -> if_template(comments = { preComments }, cond= { $boolean_expression.st }, 
              then = { $t.st }, thenindent = { $t.indent }, 
              else = { $e.st }, elseisif = { $e.isIf }, elseindent = { $e.indent})
    | ^('switch' expression  { preComments = CollectedComments; } s+=switch_section*) -> switch(comments = { preComments }, scrutinee = { $expression.st }, sections = { $s }) 
	| iteration_statement -> { $iteration_statement.st }	// while, do, for, foreach
	| jump_statement	-> { $jump_statement.st }	// break, continue, goto, return, throw
	| ^('try'  { preComments = CollectedComments; } b=block catch_clauses? finally_clause?) 
        -> try(comments = { preComments }, block = {$b.st}, blockindent = { $b.isSemi }, 
               catches = { $catch_clauses.st }, fin = { $finally_clause.st } )
	| checked_statement -> { $checked_statement.st }
	| unchecked_statement -> { $unchecked_statement.st }
	| lock_statement -> { $lock_statement.st }
	| yield_statement 
    | ^('unsafe'  { preComments = CollectedComments; }   block { someText = %op(); %{someText}.op="unsafe"; %{someText}.post = $block.st; })
      -> unsupported(comments = { preComments }, reason = {"unsafe blocks are not supported"}, text = { someText } )
	| fixed_statement
	| expression_statement  { preComments = CollectedComments; }	
         -> op(comments = { preComments }, pre={ $expression_statement.st }, op={ ";" })  // make an expression a statement, need to terminate with semi
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
declaration_statement
@init {
    List<String> preComments = null;
}:
	(local_variable_declaration { preComments = CollectedComments; } -> op(comments = { preComments }, pre = { $local_variable_declaration.st }, op = { ";" })
	| local_constant_declaration { preComments = CollectedComments; } -> op(comments = { preComments }, pre = { $local_constant_declaration.st }, op = { ";" }) ) ';' ;
local_variable_declaration:
	local_variable_type   local_variable_declarators -> local_variable_declaration(type={ $local_variable_type.st }, decs = { $local_variable_declarators.st } );
local_variable_type:
	('var') => 'var' -> unsupported(reason = {"'var' as type is unsupported"}, text = { "var" } )
	| ('dynamic') => 'dynamic' -> unsupported(reason = {"'dynamic' as type is unsupported"}, text = { "dynamic" } )
	| type  -> { $type.st } ;
local_variable_declarators:
	vs+=local_variable_declarator (',' vs+=local_variable_declarator)* -> list(items={$vs}, sep={", "});
local_variable_declarator:
	identifier ('='   local_variable_initializer)? -> local_variable_declarator(name= { $identifier.st }, init = { $local_variable_initializer.st }); 
local_variable_initializer:
	expression -> { $expression.st }
	| array_initializer 
	| stackalloc_initializer;
stackalloc_initializer:
	 stackalloc_initializer_unsupported -> unsupported(reason={"'stackalloc' is unsupported"}, text={ $stackalloc_initializer_unsupported.st });
stackalloc_initializer_unsupported:
	'stackalloc'   unmanaged_type   '['   expression   ']' -> stackalloc(type={$unmanaged_type.st}, exp = { $expression.st });
local_constant_declaration:
	'const'   type   constant_declarators ;
expression_statement:
	expression   ';'  -> { $expression.st };

// TODO: should be assignment, call, increment, decrement, and new object expressions
statement_expression:
	expression -> { $expression.st }
	;
if_statement:
	// else goes with closest if
	
	;
else_statement returns [bool isSemi, bool isIf, bool indent]:
	'else'   s=embedded_statement	{ $isSemi = $s.isSemi; $isIf = $s.isIf; $indent = $s.indent; } -> { $embedded_statement.st } ;
switch_section:
    ^(SWITCH_SECTION lab+=switch_label+ stat+=statement+) -> switch_section(labels = { $lab }, statements = { $stat });
switch_label:
	^('case'   constant_expression) -> case(what = { $constant_expression.st })
	| 'default' -> default_template() ;
iteration_statement:
	^('while' boolean_expression  SEP embedded_statement) 
          -> while(cond = { $boolean_expression.st }, block = { $embedded_statement.st }, blockindent = { $embedded_statement.indent })
	| do_statement -> { $do_statement.st }
	| ^('for' for_initializer? SEP expression? SEP for_iterator? SEP embedded_statement)
         -> for(init = { $for_initializer.st }, cond = { $expression.st }, iter = { $for_iterator.st },
                      block = { $embedded_statement.st }, blockindent = { $embedded_statement.indent })
	| ^('foreach' local_variable_type   identifier  expression SEP  embedded_statement) 
          -> foreach(type = { $local_variable_type.st }, loopid = { $identifier.st }, fromexp = { $expression.st },
                      block = { $embedded_statement.st }, blockindent = { $embedded_statement.indent });
do_statement:
	'do'   embedded_statement   'while'   '('   boolean_expression   ')'   ';' ;
for_initializer:
	(local_variable_declaration) => local_variable_declaration -> { $local_variable_declaration.st }
	| statement_expression_list -> { $statement_expression_list.st }
	;
for_iterator:
	statement_expression_list -> { $statement_expression_list.st };
statement_expression_list:
	s+=statement_expression (',' s+=statement_expression)* -> list(items = { $s }, sep = { ", " });
jump_statement:
	'break'   ';'  -> string(payload={"break;"})
	| 'continue'   ';' -> string(payload={"continue;"})
	| goto_statement-> { $goto_statement.st }
	| ^('return'   expression?) -> return(exp = { $expression.st })
	| ^('throw'   expression?) -> throw(exp = { $expression.st });
goto_statement:
	'goto'   ( identifier
			 | 'case'   constant_expression
			 | 'default')   ';' ;
catch_clauses:
    c+=catch_clause+ -> seplist(items={ $c }, sep = { "\n" }) ;
catch_clause:
	^('catch' type identifier block) -> catch_template(type = { $type.st }, id = { $identifier.st }, block = {$block.st}, blockindent = { $block.isSemi } );
finally_clause:
	^('finally'   block) -> fin(block = {$block.st}, blockindent = { $block.isSemi });
checked_statement
@init {
    StringTemplate someText = null;
}:
	'checked'   block 
        { someText = %keyword_block(); 
          %{someText}.keyword = "checked"; 
          %{someText}.block = $block.st;
          %{someText}.indent = $block.isSemi; } ->  unsupported(reason = {"checked statements are not supported"}, text = { someText } )
;
unchecked_statement
@init {
    StringTemplate someText = null;
}:
	'unchecked'   block 
        { someText = %keyword_block(); 
          %{someText}.keyword = "unchecked"; 
          %{someText}.block = $block.st;
          %{someText}.indent = $block.isSemi; } ->  unsupported(reason = {"checked statements are not supported"}, text = { someText } )
;
lock_statement
@init {
    StringTemplate someText = null;
}:
	'lock'   '('  expression   ')'   embedded_statement 
        { someText = %lock(); 
          %{someText}.exp = $expression.st; 
          %{someText}.block = $embedded_statement.st;
          %{someText}.indent = $embedded_statement.indent; } ->  unsupported(reason = {"lock() statements are not supported"}, text = { someText } )
        ;
yield_statement:
	'yield'   ('return'   expression   ';'
	          | 'break'   ';') ;

///////////////////////////////////////////////////////
//	Lexar Section
///////////////////////////////////////////////////////

predefined_type:
	  (t='bool' | t='byte'   | t='char'   | t='decimal' | t='double' | t='float'  | t='int'    | t='long'   | t='object' | t='sbyte'  
	| t='short'  | t='string' | t='uint'   | t='ulong'  | t='ushort') { collectComments($t.TokenStartIndex); } ->  string(payload={$t.text});

identifier:
 	i=IDENTIFIER { collectComments($i.TokenStartIndex); } -> string(payload= { $IDENTIFIER.text }) | also_keyword -> string(payload= { $also_keyword.text });

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
	| LONGNUMBER -> string(payload={$LONGNUMBER.text + "L"}) 
	| Hex_number -> string(payload={$Hex_number.text}) 
	| Character_literal -> string(payload={$Character_literal.text}) 
	| STRINGLITERAL -> string(payload={ $STRINGLITERAL.text }) 
	| Verbatim_string_literal -> verbatim_string(payload={ escapeJavaString($Verbatim_string_literal.text.Substring(1)) }) 
	| TRUE -> string(payload={"true"}) 
	| FALSE -> string(payload={"false"}) 
	| NULL -> string(payload={"null"}) 
	;

