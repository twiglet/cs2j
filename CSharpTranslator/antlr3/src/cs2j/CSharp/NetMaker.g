tree grammar NetMaker;

options {
    tokenVocab=cs;
    ASTLabelType=CommonTree;
	output=AST;
    language=CSharp2;
    superClass='RusticiSoftware.Translator.CSharp.CommonWalker';
}

// A scope to keep track of the namespace search path available at any point in the program
scope NSContext {

    string currentNS;

    // all namespaces in scope
    List<string> namespaces;
    // all namespaces in all scopes
    List<string> globalNamespaces;
}

// A scope to keep track of the mapping from variables to types
scope SymTab {
    Dictionary<string,TypeRepTemplate> symtab;
}

@namespace { RusticiSoftware.Translator.CSharp }

@header
{
    using System.Text;
    using RusticiSoftware.Translator.Utils;
    using RusticiSoftware.Translator.CLR;
}

@members
{
    // Initial namespace search path gathered in JavaMaker
    public List<string> SearchPath { get; set; }
    public List<string> AliasKeys { get; set; }
    public List<string> AliasNamespaces { get; set; }

    private Set<string> Imports { get; set; }

    protected CommonTree mkImports() {
    
        CommonTree root = (CommonTree)adaptor.Nil;
        
        if (Imports != null) {
            String[] sortedImports = Imports.AsArray();
            Array.Sort(sortedImports);
            foreach (string imp in sortedImports) {
                adaptor.AddChild(root, (CommonTree)adaptor.Create(IMPORT, "import"));
                adaptor.AddChild(root, (CommonTree)adaptor.Create(PAYLOAD, imp));
            }
        }
        return root;

    }

    protected string ParentNameSpace {
        get {
            return ((NSContext_scope)$NSContext.ToArray()[1]).currentNS;
        }
    }

    protected TypeRepTemplate findType(string name) {
        return AppEnv.Search($NSContext::globalNamespaces, name, new UnknownRepTemplate(name));
    }

    protected TypeRepTemplate findType(string name, TypeRepTemplate[] args) {
        StringBuilder argNames = new StringBuilder();
        bool first = true;
        if (args != null && args.Length > 0) {
            argNames.Append("[");
            foreach (TypeRepTemplate ty in args) {
                if (!first) {
                    argNames.Append(", ");
                    first = false;
                }
                argNames.Append(ty.TypeName);
            }
            argNames.Append("]");
        }
        TypeRepTemplate tyRep = AppEnv.Search($NSContext::globalNamespaces, name, new UnknownRepTemplate(name + argNames.ToString()));
        return tyRep.Instantiate(args);
    }

    private ClassRepTemplate objectType = null;

    protected ClassRepTemplate ObjectType {
        get {
            if (objectType == null) {
                objectType = (ClassRepTemplate)AppEnv.Search("System.Object", new UnknownRepTemplate("System.Object"));
            }
            return objectType;
        }
    }

    private ClassRepTemplate boolType = null;

    protected ClassRepTemplate BoolType {
        get {
            if (boolType == null) {
                boolType = (ClassRepTemplate)AppEnv.Search("System.Boolean", new UnknownRepTemplate("System.Boolean"));
            }
            return boolType;
        }
    }

    private ClassRepTemplate voidType = null;

    protected ClassRepTemplate VoidType {
        get {
            if (voidType == null) {
                voidType = (ClassRepTemplate)AppEnv.Search("System.Void", new UnknownRepTemplate("System.Void"));
            }
            return voidType;
        }
    }

    protected TypeRepTemplate SymTabLookup(string name) {
        return SymTabLookup(name, null);
    }

    protected TypeRepTemplate SymTabLookup(string name, TypeRepTemplate def) {
        object[] stabs = $SymTab.ToArray();
        foreach(SymTab_scope stabScope in stabs) {
            if (stabScope.symtab.ContainsKey(name)) {
                return stabScope.symtab[name];
            }
        }
        return def;
    }

    protected CommonTree mkJavaWrapper(string template, Dictionary<string,CommonTree> varMap, IToken tok) {
        CommonTree root = (CommonTree)adaptor.Nil;
        root = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(JAVAWRAPPER, tok, "JAVAWRAPPER"), root);
        adaptor.AddChild(root, (CommonTree)adaptor.Create(IDENTIFIER, tok, template));

        if (varMap != null) {
            foreach (String var in varMap.Keys) {
                if (varMap[var] != null) {
                    adaptor.AddChild(root, (CommonTree)adaptor.Create(IDENTIFIER, tok, var));
                    adaptor.AddChild(root, dupTree(varMap[var]));
                }
            }
        }

        return (CommonTree)adaptor.RulePostProcessing(root);
    }

    protected CommonTree wrapExpression(CommonTree e, IToken tok) {
        CommonTree root = (CommonTree)adaptor.Nil;
        root = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(JAVAWRAPPEREXPRESSION, tok, "EXPRESSION"), root);
        adaptor.AddChild(root, dupTree(e));

        return (CommonTree)adaptor.RulePostProcessing(root);
    }

    protected CommonTree wrapArgument(CommonTree e, IToken tok) {
        CommonTree root = (CommonTree)adaptor.Nil;
        root = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(JAVAWRAPPERARGUMENT, tok, "ARGUMENT"), root);
        adaptor.AddChild(root, dupTree(e));

        return (CommonTree)adaptor.RulePostProcessing(root);
    }

    protected CommonTree wrapTypeOfType(TypeRepTemplate t, IToken tok) {
        CommonTree root = (CommonTree)adaptor.Nil;
        root = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(JAVAWRAPPEREXPRESSION, tok, "EXPRESSION"), root);
        adaptor.AddChild(root, (CommonTree)adaptor.Create(IDENTIFIER, tok, t.Java));
        return (CommonTree)adaptor.RulePostProcessing(root);
    }

    protected CommonTree mkArray(CommonTree t, IToken tok) {
        if (!t.IsNil) {
            adaptor.AddChild(t, (CommonTree)adaptor.Create(OPEN_BRACKET, tok, "["));
            adaptor.AddChild(t, (CommonTree)adaptor.Create(CLOSE_BRACKET, tok, "]"));
        }
        return t;
    }

    protected CommonTree dupTree(CommonTree t) {
        return (CommonTree)adaptor.DupTree(t);
    }

    protected static readonly string[] ScruTypeStrs = new string[] { "System.Int32",
                                                                     "System.Int64",
                                                                     "System.Char",
                                                                     "System.Enum", 
                                                                    };

    protected bool typeIsInvalidForScrutinee(TypeRepTemplate sType) {
        bool ret = true;

        foreach (string t in ScruTypeStrs)
        {
            if (sType.IsA(AppEnv.Search(t), AppEnv))
            {
                ret = false;
                break;
            }
        }

        return ret;
        
    }

    // counter to ensure that the vars we introduce are unique 
    protected int dummyScrutVarCtr = 0;
    protected int dummyForeachVarCtr = 0;

    protected CommonTree convertSectionsToITE(List sections) {
        CommonTree ret = null;
        if (sections != null && sections.Count > 0) {
            ret = dupTree((CommonTree)sections[sections.Count - 1]);
            for(int i = sections.Count - 2; i >= 0; i--) {
                CommonTree section = dupTree((CommonTree)sections[i]);
                // section is either ^(IF ...) or "else ^(IF ....)" we need to insert ret into the IF
                if (section.IsNil) {
                    section.Children[section.Children.Count-1].AddChild(ret);
                }
                else {
                    section.AddChild(ret);
                }
                ret = section;
            } 
        }
        return ret;
    }

    // In switch sections we want to remove final break statements if we have converted to if-then-else 
    protected CommonTree stripFinalBreak(CommonTree stats) {
    
        CommonTree ret = stats;
        if (stats.IsNil) {
            // A list of statements
            // look for an ending of "break [;]"
            int len = stats.Children.Count;
            int breakPos = len - 1;
            if ( len > 1 && stats.Children[len-1].Type == SEMI ) {
                breakPos = len -2;
            }
            if (stats.Children[breakPos].Type != BREAK) {
                // not found
                breakPos = -1;
            }
            if (breakPos >= 0) {
                // delete from break to end
                for (int i = len-1; i >= breakPos; i--) {
                    stats.DeleteChild(i);
                }
            }
        }
        return ret;
    }

    // if slist is a list of statements surrounded by braces, then strip them out. 
    protected CommonTree stripPossibleBraces(CommonTree slist) {
        CommonTree ret = slist;
        if (ret.IsNil && adaptor.GetChildCount(ret) >= 2) {
            if (adaptor.GetType(adaptor.GetChild(ret,0)) == OPEN_BRACE &&
                adaptor.GetType(adaptor.GetChild(ret,adaptor.GetChildCount(ret)-1)) == CLOSE_BRACE) {
                adaptor.DeleteChild(ret,adaptor.GetChildCount(ret)-1); 
                adaptor.DeleteChild(ret,0); 
            }
        }
        return ret;
    }

    // embeddedStatement is either ";", "{ .... }", or a single statement
    protected CommonTree prefixCast(CommonTree targetTy, CommonTree id, CommonTree castTy, CommonTree foreachVar, CommonTree embeddedStatement, IToken tok) {
        CommonTree root = embeddedStatement;
        if (!embeddedStatement.IsNil && adaptor.GetType(embeddedStatement) == SEMI) {
            // Do nothing, id is unused  
        }
        else {
            // Make cast statement
            CommonTree kast = (CommonTree)adaptor.Nil;
            kast = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(CAST_EXPR, tok, "CAST"), kast);
            adaptor.AddChild(kast, (CommonTree)adaptor.DupTree(castTy));
            adaptor.AddChild(kast, (CommonTree)adaptor.DupTree(foreachVar));
            CommonTree vardec = (CommonTree)adaptor.Nil;
            adaptor.AddChild(vardec, (CommonTree)adaptor.DupTree(targetTy));
            adaptor.AddChild(vardec, (CommonTree)adaptor.DupTree(id));
            adaptor.AddChild(vardec, (CommonTree)adaptor.Create(ASSIGN, tok, "="));
            adaptor.AddChild(vardec, (CommonTree)adaptor.DupTree(kast));
            adaptor.AddChild(vardec, (CommonTree)adaptor.Create(SEMI, tok, ";"));
            root = (CommonTree)adaptor.Nil;
            // Make a { <cast> statement }
            adaptor.AddChild(root, (CommonTree)adaptor.Create(OPEN_BRACE, tok, "{"));
            adaptor.AddChild(root, vardec);
            // todo: strip "{ }"
            adaptor.AddChild(root, stripPossibleBraces((CommonTree)adaptor.DupTree(embeddedStatement)));
            adaptor.AddChild(root, (CommonTree)adaptor.Create(CLOSE_BRACE, tok, "}"));
        }
        return (CommonTree)adaptor.RulePostProcessing(root);
    }

    private Dictionary<int,string> _boxTypeMap = null;
    protected Dictionary<int,string> BoxTypeMap {
        get {
            if (_boxTypeMap == null) {
                _boxTypeMap  = new Dictionary<int,string>();
                // Initialize boxTypeMap (see JLS, ed 3 sec 5.1.7)
                _boxTypeMap[BOOL] = "Boolean";
                _boxTypeMap[BYTE] = "Byte";
                _boxTypeMap[CHAR] = "Character";
                _boxTypeMap[SHORT] = "Short";
                _boxTypeMap[INT] = "Integer";
                _boxTypeMap[LONG] = "Long";
                _boxTypeMap[FLOAT] = "Float";
                _boxTypeMap[DOUBLE] = "Double";
            }
            return _boxTypeMap;
        }
    }
    

    // if slist is a list of statements surrounded by braces, then strip them out. 
    protected CommonTree mkBoxedType(CommonTree ty, IToken tok) {
        CommonTree ret = ty;
        // Make sure its just  plain old predefined type
        if (!ty.IsNil && adaptor.GetType(ty) == TYPE && adaptor.GetChildCount(ty) == 1 && 
            BoxTypeMap.ContainsKey(adaptor.GetType(((CommonTree)adaptor.GetChild(ty,0)))) ) {
            ret =  (CommonTree)adaptor.Nil;
            ret = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(TYPE, tok, "TYPE"), ret);
            adaptor.AddChild(ret, (CommonTree)adaptor.Create(IDENTIFIER, tok, BoxTypeMap[adaptor.GetType((CommonTree)adaptor.GetChild(ty,0))]));
        }
        return ret;
    }
}

compilation_unit
scope NSContext;
@init {

    Imports = new Set<string>();

    // TODO: Do we need to ensure we have access to System? If so, can add it here.
    $NSContext::namespaces = SearchPath ?? new List<string>();
    $NSContext::globalNamespaces = SearchPath ?? new List<string>();
}:
	^(pkg=PACKAGE ns=PAYLOAD { $NSContext::currentNS = $ns.text; } m=modifiers? dec=type_declaration  )
    -> ^($pkg $ns  { mkImports() } $m? $dec);

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
    ^(CONST attributes? modifiers? type constant_declarators[$type.dotNetType])
    | ^(EVENT attributes? modifiers? event_declaration)
    | ^(METHOD attributes? modifiers? type member_name type_parameter_constraints_clauses? type_parameter_list? formal_parameter_list? method_body exception*)
    | ^(INTERFACE attributes? modifiers? interface_declaration)
    | ^(CLASS attributes? modifiers? class_declaration)
    | ^(FIELD attributes? modifiers? type field_declaration[$type.dotNetType])
    | ^(OPERATOR attributes? modifiers? type operator_declaration)
    | ^(ENUM attributes? modifiers? enum_declaration)
    | ^(DELEGATE attributes? modifiers? delegate_declaration)
    | ^(CONVERSION_OPERATOR attributes? modifiers? conversion_operator_declaration[$attributes.tree, $modifiers.tree]) -> conversion_operator_declaration
    | ^(CONSTRUCTOR attributes? modifiers? identifier  formal_parameter_list? block exception*)
    | ^(STATIC_CONSTRUCTOR attributes? modifiers? block)
    ;

exception:
    EXCEPTION;

// rmId is the rightmost ID in an expression like fdfd.dfdsf.returnme, otherwise it is null
// used in switch labels to strip down qualified types, which Java doesn't grok
primary_expression returns [TypeRepTemplate dotNetType, String rmId, TypeRepTemplate typeofType]
scope {
    bool parentIsApply;
}
@init {
    $primary_expression::parentIsApply = false;
    CommonTree ret = null;
    TypeRepTemplate expType = SymTabLookup("this");
    bool implicitThis = true;
}
@after {
    if (ret != null)
        $primary_expression.tree = ret;
}:
    ^(INDEX ie=expression expression_list?)
        {
            if ($ie.dotNetType != null) {
                $dotNetType = new UnknownRepTemplate($ie.dotNetType.TypeName+".INDEXER");
                ResolveResult indexerResult = $ie.dotNetType.ResolveIndexer($expression_list.expTypes ?? new List<TypeRepTemplate>(), AppEnv);
                if (indexerResult != null) {
                    IndexerRepTemplate indexerRep = indexerResult.Result as IndexerRepTemplate;
                    if (!String.IsNullOrEmpty(indexerRep.JavaGet)) {
                        Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                        myMap["this"] = wrapExpression($ie.tree, $ie.tree.Token);
                        for (int idx = 0; idx < indexerRep.Params.Count; idx++) {
                            myMap[indexerRep.Params[idx].Name] = wrapArgument($expression_list.expTrees[idx], $ie.tree.Token);
                            if (indexerRep.Params[idx].Name.StartsWith("TYPEOF") && $expression_list.expTreeTypeofTypes[idx] != null) {
                                // if this argument is a typeof expression then add a TYPEOF_TYPEOF-> typeof's type mapping
                                myMap[indexerRep.Params[idx].Name + "_TYPE"] = wrapTypeOfType($expression_list.expTreeTypeofTypes[idx], $ie.tree.Token);
                            }
                        }
                        ret = mkJavaWrapper(indexerResult.Result.Java, myMap, $ie.tree.Token);
                        Imports.Add(indexerResult.Result.Imports);
                        $dotNetType = indexerResult.ResultType; 
                    }
                }
            }
        }
    | (^(APPLY (^('.' expression identifier)|identifier) argument_list?)) => 
           ^(APPLY (^('.' e2=expression {expType = $e2.dotNetType; implicitThis = false;} i2=identifier)|i2=identifier) argument_list?)
        {
            if (expType != null) {
                $dotNetType = new UnknownRepTemplate(expType.TypeName+".APPLY");
                ResolveResult methodResult = expType.Resolve($i2.thetext, $argument_list.argTypes ?? new List<TypeRepTemplate>(), AppEnv);
                if (methodResult != null) {
                    Debug($i2.tree.Token.Line + ": Found '" + $i2.thetext + "'");
                    MethodRepTemplate methodRep = methodResult.Result as MethodRepTemplate;
                    Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                    if (!implicitThis) {
                        myMap["this"] = wrapExpression($e2.tree, $i2.tree.Token);
                    }
                    for (int idx = 0; idx < methodRep.Params.Count; idx++) {
                        myMap[methodRep.Params[idx].Name] = wrapArgument($argument_list.argTrees[idx], $i2.tree.Token);
                        if (methodRep.Params[idx].Name.StartsWith("TYPEOF") && $argument_list.argTreeTypeofTypes[idx] != null) {
                            // if this argument is a typeof expression then add a TYPEOF_TYPEOF-> typeof's type mapping
                            myMap[methodRep.Params[idx].Name + "_TYPE"] = wrapTypeOfType($argument_list.argTreeTypeofTypes[idx], $i2.tree.Token);
                        }
                    }
                    ret = mkJavaWrapper(methodResult.Result.Java, myMap, $i2.tree.Token);
                    Imports.Add(methodResult.Result.Imports);
                    $dotNetType = methodResult.ResultType; 
                }
            }
        }
    | ^(APPLY {$primary_expression::parentIsApply = true; } expression {$primary_expression::parentIsApply = false; } argument_list?)
    | ^(POSTINC expression)    { $dotNetType = $expression.dotNetType; }
    | ^(POSTDEC expression)    { $dotNetType = $expression.dotNetType; }
    | ^(d1='.' e1=expression i1=identifier generic_argument_list?)
        { 
            // Possibilities:
            // - accessing a property/field of some object
            // - a qualified type name
            // - part of a qualified type name
            expType = $e1.dotNetType;
            
            // Is it a property read? Ensure we are not being applied to arguments or about to be assigned
            if (expType != null &&
                ($primary_expression.Count == 1 || !((primary_expression_scope)($primary_expression.ToArray()[1])).parentIsApply)) {
                    
                Debug($d1.token.Line + ": '" + $i1.thetext + "' might be a property");

                $dotNetType = new UnknownRepTemplate(expType.TypeName+".DOTACCESS");

                ResolveResult fieldResult = expType.Resolve($i1.thetext, AppEnv);
                if (fieldResult != null) {
                    Debug($d1.token.Line + ": Found '" + $i1.thetext + "'");
                    Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                    myMap["this"] = wrapExpression($e1.tree, $i1.tree.Token);
                    ret = mkJavaWrapper(fieldResult.Result.Java, myMap, $i1.tree.Token);
                    Imports.Add(fieldResult.Result.Imports);
                    $dotNetType = fieldResult.ResultType; 
                }
                else if ($e1.dotNetType is UnknownRepTemplate) {
                    string staticType = $e1.dotNetType + "." + $i1.thetext;
                    TypeRepTemplate type = findType(staticType);
                    if (type != null) {
                        Imports.Add(type.Imports);
                        $dotNetType = type;
                    }
                    else {
                        $dotNetType = new UnknownRepTemplate(staticType);
                    }
                }
            }
            $rmId = $identifier.thetext;
        }         
    | ^('->' expression identifier generic_argument_list?)
	| predefined_type                                                { $dotNetType = $predefined_type.dotNetType; }         
	| 'this'                                                         { $dotNetType = SymTabLookup("this"); }         
	| SUPER                                                          { $dotNetType = SymTabLookup("super"); }         
	| (identifier    generic_argument_list) => identifier   generic_argument_list
    | i=identifier                                                     
        { 
            // Possibilities:
            // - a variable in scope.
            // - a property/field of current object
            // - a type name
            // - part of a type name
            bool found = false;
            TypeRepTemplate idType = SymTabLookup($identifier.thetext);
            if (idType != null) {
                $dotNetType = idType;
                found = true;
            }
            if (!found) {
                // Not a variable, is it a property?
                TypeRepTemplate thisType = SymTabLookup("this");

                // Is it a property read? Ensure we are not being applied to arguments or about to be assigned
                if (thisType != null &&
                    ($primary_expression.Count == 1 || !((primary_expression_scope)($primary_expression.ToArray()[1])).parentIsApply)) {
                    
                    Debug($identifier.tree.Token.Line + ": '" + $identifier.thetext + "' might be a property");
                    ResolveResult fieldResult = thisType.Resolve($identifier.thetext, AppEnv);
                    if (fieldResult != null) {
                        Debug($identifier.tree.Token.Line + ": Found '" + $identifier.thetext + "'");
                        ret = mkJavaWrapper(fieldResult.Result.Java, null, $i.tree.Token);
                        Imports.Add(fieldResult.Result.Imports);
                        $dotNetType = fieldResult.ResultType; 
                        found = true;
                    }
                }
            }
            if (!found) {
                // Not a variable, not a property read, is it a type name?
                TypeRepTemplate staticType = findType($i.thetext);
                if (staticType != null) {
                    Imports.Add(staticType.Imports);
                    $dotNetType = staticType;
                    found = true;
                }
            }
            if (!found) {
                // Not a variable, not a property read, not a type, is it part of a type name?
                $dotNetType = new UnknownRepTemplate($identifier.thetext);
            }
        }         
    | primary_expression_start                        { $dotNetType = $primary_expression_start.dotNetType; }  
    | literal                                         { $dotNetType = $literal.dotNetType; }  
//	('this'    brackets) => 'this'   brackets   primary_expression_part*
//	| ('base'   brackets) => 'this'   brackets   primary_expression_part*
//	| primary_expression_start   primary_expression_part*
    | ^(n=NEW type argument_list? object_or_collection_initializer?)
        {
            ClassRepTemplate conType = $type.dotNetType as ClassRepTemplate;
            $dotNetType = $type.dotNetType;
            ResolveResult conResult = conType.Resolve($argument_list.argTypes, AppEnv);
            if (conResult != null) {
                ConstructorRepTemplate conRep = conResult.Result as ConstructorRepTemplate;
                Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                for (int idx = 0; idx < conRep.Params.Count; idx++) {
                    myMap[conRep.Params[idx].Name] = wrapArgument($argument_list.argTrees[idx], $n.token);
                }
                ret = mkJavaWrapper(conResult.Result.Java, myMap, $n.token);
                Imports.Add(conResult.Result.Imports);
                $dotNetType = conResult.ResultType; 
            }
        }
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
	| typeof_expression          { $dotNetType = $typeof_expression.dotNetType; $typeofType = $typeof_expression.typeofType; }   // typeof(Foo).Name
	;

primary_expression_start returns [TypeRepTemplate dotNetType]:
	 ^('::' identifier identifier)
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
argument_list returns [List<TypeRepTemplate> argTypes, List<CommonTree> argTrees, List<TypeRepTemplate> argTreeTypeofTypes]
@init {
    $argTypes = new List<TypeRepTemplate>();
    $argTrees = new List<CommonTree>();
    $argTreeTypeofTypes = new List<TypeRepTemplate>();
}: 
	^(ARGS (argument { $argTypes.Add($argument.dotNetType); $argTrees.Add(dupTree($argument.tree)); $argTreeTypeofTypes.Add($argument.typeofType); })+);
// 4.0
argument returns [TypeRepTemplate dotNetType, TypeRepTemplate typeofType]:
	argument_name   argument_value { $dotNetType = $argument_value.dotNetType; $typeofType = $argument_value.typeofType; }
	| argument_value { $dotNetType = $argument_value.dotNetType; $typeofType = $argument_value.typeofType; }
    ;
argument_name:
	identifier   ':';
argument_value returns [TypeRepTemplate dotNetType, TypeRepTemplate typeofType]:
	expression { $dotNetType = $expression.dotNetType; $typeofType = $expression.typeofType; } 
	| ref_variable_reference { $dotNetType = $ref_variable_reference.dotNetType; $typeofType = $ref_variable_reference.typeofType; } 
	| 'out'   variable_reference { $dotNetType = $variable_reference.dotNetType; $typeofType = $variable_reference.typeofType; } ;
ref_variable_reference returns [TypeRepTemplate dotNetType, TypeRepTemplate typeofType]:
	'ref' 
		(('('   type   ')') =>   '('   type   ')'   (ref_variable_reference | variable_reference) { $dotNetType = $type.dotNetType; }   // SomeFunc(ref (int) ref foo)
																									// SomeFunc(ref (int) foo)
		| v1=variable_reference { $dotNetType = $v1.dotNetType; $typeofType = $v1.typeofType; });	// SomeFunc(ref foo)
// lvalue
variable_reference returns [TypeRepTemplate dotNetType, TypeRepTemplate typeofType]:
	expression { $dotNetType = $expression.dotNetType; $typeofType = $expression.typeofType; };
rank_specifiers[TypeRepTemplate inTy] returns [TypeRepTemplate dotNetType]
@init {
    TypeRepTemplate ty = $inTy;
}: 
        (rank_specifier[ty] { ty = $rank_specifier.dotNetType;} )+ { $dotNetType = ty; };        
rank_specifier[TypeRepTemplate inTy] returns [TypeRepTemplate dotNetType]:
	'['   /*dim_separators?*/   ']' { if ($inTy != null) { $dotNetType = findType("System.Array", new TypeRepTemplate[] {$inTy}); } } ;
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
primary_or_array_creation_expression returns [TypeRepTemplate dotNetType, String rmId, TypeRepTemplate typeofType]:
	(array_creation_expression) => array_creation_expression { $dotNetType = $array_creation_expression.dotNetType; }
	| primary_expression { $dotNetType = $primary_expression.dotNetType; $rmId = $primary_expression.rmId; $typeofType = $primary_expression.typeofType; }
	;
// new Type[2] { }
array_creation_expression returns [TypeRepTemplate dotNetType]:
	^('new'   
		(type   ('['   expression_list   ']'   
					( rank_specifiers[$type.dotNetType]?   array_initializer?	// new int[4]
					// | invocation_part*
					| ( ((arguments   ('['|'.'|'->')) => arguments   invocation_part)// new object[2].GetEnumerator()
					  | invocation_part)*   arguments
					)							// new int[4]()
				| array_initializer	{ $dotNetType = $type.dotNetType; } 	
				)
		| rank_specifier[null]   // [,]
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

typeof_expression returns [TypeRepTemplate dotNetType, TypeRepTemplate typeofType]: 
	^('typeof'  (unbound_type_name | type { $typeofType = $type.dotNetType; } | 'void' { $typeofType = AppEnv.Search("System.Void"); }) ) { $dotNetType = AppEnv.Search("System.Type"); };
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

type_name returns [string name, TypeRepTemplate dotNetType]: 
	namespace_or_type_name { $name = $namespace_or_type_name.name; $dotNetType = findType($namespace_or_type_name.name); } ;
namespace_or_type_name returns [String name, List<string> tyargs]
@init {
    TypeRepTemplate tyRep = null;
}: 
	 type_or_generic { $name = $type_or_generic.name; $tyargs = $type_or_generic.tyargs; }
    | ^('::' namespace_or_type_name type_or_generic) { $name = "System.Object"; } // give up, we don't support these
    | ^(d='.'   n1=namespace_or_type_name tg1=type_or_generic) { WarningAssert($n1.tyargs == null, $d.token.Line, "Didn't expect type arguments in prefix of type name"); $name = $n1.name + "." + $type_or_generic.name; $tyargs = $type_or_generic.tyargs; tyRep = findType($name); if (tyRep != null) Imports.Add(tyRep.Imports); } 
        -> { tyRep != null }? IDENTIFIER[$d.token, tyRep.Java]
        -> ^($d $n1 $tg1)
     ;

type_or_generic returns [String name, List<String> tyargs]
:
	(identifier_type   generic_argument_list) => t=identifier_type { $name = $identifier_type.thetext; }  generic_argument_list { $tyargs = $generic_argument_list.argTexts; }
	| t=identifier_type { $name = $identifier_type.thetext; } ;

identifier_type returns [string thetext]
@init {
    TypeRepTemplate tyRep = null;
}
@after{
    $thetext = $t.thetext;
}:
    t=identifier { tyRep = findType($t.thetext); if (tyRep != null)  Imports.Add(tyRep.Imports); } 
        -> { tyRep != null }? IDENTIFIER[$t.tree.Token, tyRep.Java]
        -> $t;

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
	access_identifier;

generic_argument_list returns [List<string> argTexts]: 
	'<'   type_arguments   '>' { $argTexts = $type_arguments.tyTexts; };
type_arguments  returns [List<string> tyTexts]
@init {
    $tyTexts = new List<String>();
}: 
	t1=type { $tyTexts.Add($t1.dotNetType.TypeName); } (',' tn=type { $tyTexts.Add($tn.dotNetType.TypeName); })* ;

type returns [TypeRepTemplate dotNetType]
:
    ^(TYPE (predefined_type { $dotNetType = $predefined_type.dotNetType; } 
           | type_name { $dotNetType = $type_name.dotNetType; } 
           | 'void' { $dotNetType = AppEnv["System.Void"]; } )  
        (rank_specifiers[$dotNetType] { $dotNetType = $rank_specifiers.dotNetType; })? '*'* '?'?);

non_nullable_type returns [TypeRepTemplate dotNetType]:
    type { $dotNetType = $type.dotNetType; } ;
non_array_type returns [TypeRepTemplate dotNetType]:
	type { $dotNetType = $type.dotNetType; } ;
array_type returns [TypeRepTemplate dotNetType]:
	type { $dotNetType = $type.dotNetType; } ;
unmanaged_type returns [TypeRepTemplate dotNetType]:
	type { $dotNetType = $type.dotNetType; } ;
class_type returns [TypeRepTemplate dotNetType]:
	type { $dotNetType = $type.dotNetType; } ;
pointer_type returns [TypeRepTemplate dotNetType]:
	type { $dotNetType = $type.dotNetType; } ;


///////////////////////////////////////////////////////
//	Statement Section
///////////////////////////////////////////////////////
block
scope SymTab;
@init {
    $SymTab::symtab = new Dictionary<string,TypeRepTemplate>();
}:
	';'
	| '{'   statement_list?   '}';
statement_list:
	statement+ ;
	
///////////////////////////////////////////////////////
//	Expression Section
///////////////////////////////////////////////////////	
expression returns [TypeRepTemplate dotNetType, String rmId, TypeRepTemplate typeofType]: 
	(unary_expression   assignment_operator) => assignment	    { $dotNetType = VoidType; }
	| non_assignment_expression                                 { $dotNetType = $non_assignment_expression.dotNetType; $rmId = $non_assignment_expression.rmId; $typeofType = $non_assignment_expression.typeofType; }
	;
expression_list returns [List<TypeRepTemplate> expTypes, List<CommonTree> expTrees, List<TypeRepTemplate> expTreeTypeofTypes]
@init {
    $expTypes = new List<TypeRepTemplate>();
    $expTrees = new List<CommonTree>();
    $expTreeTypeofTypes = new List<TypeRepTemplate>();
}:
	e1=expression { $expTypes.Add($e1.dotNetType); $expTrees.Add(dupTree($e1.tree)); $expTreeTypeofTypes.Add($e1.typeofType); }
      (','   en=expression { $expTypes.Add($en.dotNetType); $expTrees.Add(dupTree($en.tree)); $expTreeTypeofTypes.Add($en.typeofType); })* ;

assignment
@init {
    CommonTree ret = null;
    bool isThis = false;
}
@after {
    if (ret != null)
        $assignment.tree = ret;
}:
    ((^('.' expression identifier generic_argument_list?) | identifier) '=')  => 
        (^('.' se=expression i=identifier generic_argument_list?) | i=identifier { isThis = true;})  a='=' rhs=expression 
        {
            TypeRepTemplate seType = (isThis ? SymTabLookup("this") : $se.dotNetType);
            if (seType != null) {
                ResolveResult fieldResult = seType.Resolve($i.thetext, AppEnv);
                if (fieldResult != null && fieldResult.Result is PropRepTemplate) {
                    Debug($i.tree.Token.Line + ": Found '" + $i.thetext + "'");
                    Dictionary<string,CommonTree> valMap = new Dictionary<string,CommonTree>();
                    if (!isThis)
                        valMap["this"] = wrapExpression($se.tree, $i.tree.Token);
                    valMap["value"] = wrapExpression($rhs.tree, $i.tree.Token);
                    ret = mkJavaWrapper(((PropRepTemplate)fieldResult.Result).JavaSet, valMap, $a.token);
                    Imports.Add(fieldResult.Result.Imports);
                }
            }
        }
    | (^(INDEX expression expression_list?) '=')  => 
        ^(INDEX ie=expression expression_list?)   ia='=' irhs=expression 
        {
            if ($ie.dotNetType != null) {
                ResolveResult indexerResult = $ie.dotNetType.ResolveIndexer($expression_list.expTypes ?? new List<TypeRepTemplate>(), AppEnv);
                if (indexerResult != null) {
                    IndexerRepTemplate indexerRep = indexerResult.Result as IndexerRepTemplate;
                    if (!String.IsNullOrEmpty(indexerRep.JavaSet)) {
                        Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                        myMap["this"] = wrapExpression($ie.tree, $ie.tree.Token);
                        myMap["value"] = wrapExpression($irhs.tree, $irhs.tree.Token);
                        for (int idx = 0; idx < indexerRep.Params.Count; idx++) {
                            myMap[indexerRep.Params[idx].Name] = wrapArgument($expression_list.expTrees[idx], $ie.tree.Token);
                            if (indexerRep.Params[idx].Name.StartsWith("TYPEOF") && $expression_list.expTreeTypeofTypes[idx] != null) {
                                // if this argument is a typeof expression then add a TYPEOF_TYPEOF-> typeof's type mapping
                                myMap[indexerRep.Params[idx].Name + "_TYPE"] = wrapTypeOfType($expression_list.expTreeTypeofTypes[idx], $ie.tree.Token);
                            }
                        }
                        ret = mkJavaWrapper(indexerRep.JavaSet, myMap, $ie.tree.Token);
                        Imports.Add(indexerRep.Imports);
                    }   
                }
            }
        }
    | unary_expression   assignment_operator expression ;


unary_expression returns [TypeRepTemplate dotNetType, String rmId, TypeRepTemplate typeofType]: 
	//('(' arguments ')' ('[' | '.' | '(')) => primary_or_array_creation_expression	

    cast_expression                             { $dotNetType = $cast_expression.dotNetType; }
	| primary_or_array_creation_expression      { $dotNetType = $primary_or_array_creation_expression.dotNetType; $rmId = $primary_or_array_creation_expression.rmId; $typeofType = $primary_or_array_creation_expression.typeofType; }
	| ^(MONOPLUS u1=unary_expression)           { $dotNetType = $u1.dotNetType; }
	| ^(MONOMINUS u2=unary_expression)          { $dotNetType = $u2.dotNetType; }
	| ^(MONONOT u3=unary_expression)            { $dotNetType = $u3.dotNetType; }
	| ^(MONOTWIDDLE u4=unary_expression)        { $dotNetType = $u4.dotNetType; }
	| ^(PREINC u5=unary_expression)             { $dotNetType = $u5.dotNetType; }
	| ^(PREDEC u6=unary_expression)             { $dotNetType = $u6.dotNetType; }
	| ^(MONOSTAR unary_expression)              { $dotNetType = ObjectType; }
	| ^(ADDRESSOF unary_expression)             { $dotNetType = ObjectType; }
	| ^(PARENS expression)                      { $dotNetType = $expression.dotNetType; $rmId = $expression.rmId; $typeofType = $expression.typeofType; }
	;

cast_expression  returns [TypeRepTemplate dotNetType]
@init {
    CommonTree ret = null;
}
@after {
    if (ret != null)
        $cast_expression.tree = ret;
}:
    ^(c=CAST_EXPR type unary_expression) 
       { 
            $dotNetType = $type.dotNetType;
            if ($type.dotNetType != null && $unary_expression.dotNetType != null) {
                // see if expression's type has a cast to type
                ResolveResult kaster = $unary_expression.dotNetType.ResolveCastTo($type.dotNetType, AppEnv);
                if (kaster == null) {
                    // see if type has a cast from expression's type
                    kaster = $type.dotNetType.ResolveCastFrom($unary_expression.dotNetType, AppEnv);
                }
                if (kaster != null) {
                    Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                    myMap["expr"] = wrapExpression($unary_expression.tree, $c.token);
                    myMap["TYPEOF_totype"] = wrapTypeOfType($type.dotNetType, $c.token);
                    myMap["TYPEOF_expr"] = wrapTypeOfType($unary_expression.dotNetType, $c.token);
                    ret = mkJavaWrapper(kaster.Result.Java, myMap, $c.token);
                    Imports.Add(kaster.Result.Imports);
                }
            }
       }
         ->  ^($c  { ($unary_expression.dotNetType != null && $unary_expression.dotNetType.TypeName == "System.Object" ? mkBoxedType($type.tree, $type.tree.Token) : $type.tree) }  unary_expression)         
//         ->  ^($c  { ($type.dotNetType.IsUnboxedType && !$unary_expression.dotNetType.IsUnboxedType ? mkBoxedType($type.tree, $type.tree.Token) : $type.tree) }  unary_expression)         
;         
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

non_assignment_expression returns [TypeRepTemplate dotNetType, String rmId, TypeRepTemplate typeofType]:
	//'non ASSIGNment'
	(anonymous_function_signature   '=>')	=> lambda_expression
	| (query_expression) => query_expression 
	|     ^(COND_EXPR non_assignment_expression e1=expression e2=expression)  {$dotNetType = $e1.dotNetType; }
        | ^('??' n1=non_assignment_expression non_assignment_expression)      {$dotNetType = $n1.dotNetType; }
        | ^('||' n2=non_assignment_expression non_assignment_expression)      {$dotNetType = $n2.dotNetType; }
        | ^('&&' n3=non_assignment_expression non_assignment_expression)      {$dotNetType = $n3.dotNetType; }
        | ^('|' n4=non_assignment_expression non_assignment_expression)       {$dotNetType = $n4.dotNetType; }
        | ^('^' n5=non_assignment_expression non_assignment_expression)       {$dotNetType = $n5.dotNetType; }
        | ^('&' n6=non_assignment_expression non_assignment_expression)       {$dotNetType = $n6.dotNetType; }
        | ^('==' non_assignment_expression non_assignment_expression)         {$dotNetType = BoolType; }
        | ^('!=' non_assignment_expression non_assignment_expression)         {$dotNetType = BoolType; }
        | ^('>' non_assignment_expression non_assignment_expression)          {$dotNetType = BoolType; }
        | ^('<' non_assignment_expression non_assignment_expression)          {$dotNetType = BoolType; }
        | ^('>=' non_assignment_expression non_assignment_expression)         {$dotNetType = BoolType; }
        | ^('<=' non_assignment_expression non_assignment_expression)         {$dotNetType = BoolType; }
        | ^(INSTANCEOF non_assignment_expression non_nullable_type)           {$dotNetType = BoolType; }
        | ^('<<' n7=non_assignment_expression non_assignment_expression)      {$dotNetType = $n7.dotNetType; }
        | ^('>>' n8=non_assignment_expression non_assignment_expression)      {$dotNetType = $n8.dotNetType; }
// TODO: need to munge these numeric types
        | ^('+' n9=non_assignment_expression non_assignment_expression)       {$dotNetType = $n9.dotNetType; }
        | ^('-' n10=non_assignment_expression non_assignment_expression)      {$dotNetType = $n10.dotNetType; }
        | ^('*' n11=non_assignment_expression non_assignment_expression)      {$dotNetType = $n11.dotNetType; }
        | ^('/' n12=non_assignment_expression non_assignment_expression)      {$dotNetType = $n12.dotNetType; }
        | ^('%' n13=non_assignment_expression non_assignment_expression)      {$dotNetType = $n13.dotNetType; }
 //       | ^(UNARY_EXPRESSION unary_expression)
        | unary_expression                                                    {$dotNetType = $unary_expression.dotNetType; $rmId = $unary_expression.rmId; $typeofType = $unary_expression.typeofType; }
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

class_declaration
scope NSContext,SymTab;
@init {
    $NSContext::namespaces = new List<string>();
    $NSContext::globalNamespaces = new List<string>(((NSContext_scope)$NSContext.ToArray()[1]).globalNamespaces);
    $SymTab::symtab = new Dictionary<string, TypeRepTemplate>();
}
:
   ^(CLASS identifier { $NSContext::currentNS = ParentNameSpace + "." + $identifier.thetext; } type_parameter_constraints_clauses? type_parameter_list?
         class_implements? 
         { 
            $NSContext::namespaces.Add($NSContext::currentNS);
            $NSContext::globalNamespaces.Add($NSContext::currentNS);
            ClassRepTemplate classTypeRep = (ClassRepTemplate)AppEnv.Search($NSContext::currentNS);
            $SymTab::symtab["this"] = classTypeRep;
            ClassRepTemplate baseType = ObjectType;
            if (classTypeRep.Inherits != null && classTypeRep.Inherits.Length > 0) {
                // if Inherits[0] is a class then it is parent, else system.object
                ClassRepTemplate parent = AppEnv.Search(classTypeRep.Uses, classTypeRep.Inherits[0], ObjectType) as ClassRepTemplate;
                if (parent != null)
                    baseType = parent;
            }
            $SymTab::symtab["super"] = baseType;
         }
         class_body ) ;

type_parameter_list:
    (attributes? type_parameter)+ ;

type_parameter:
    identifier ;

class_extends:
	class_extend+ ;
class_extend:
	^(EXTENDS type) ;

// If first implements type is a class then convert to extends
class_implements:
	class_implement_or_extend class_implement* ;

class_implement_or_extend:
	^(i=IMPLEMENTS t=type) -> { $t.dotNetType is ClassRepTemplate }? ^(EXTENDS[$i.token, "extends"] type)
                           -> ^($i $t);
	
class_implement:
	^(IMPLEMENTS type) ;
	
interface_type_list:
	type (','   type)* ;

class_body:
	'{'   class_member_declarations?   '}' ;
class_member_declarations:
	class_member_declaration+ ;

///////////////////////////////////////////////////////
constant_declaration:
	'const'   type   constant_declarators[$type.dotNetType]   ';' ;
constant_declarators[TypeRepTemplate ty]:
	constant_declarator[$ty] (',' constant_declarator[$ty])* ;
constant_declarator[TypeRepTemplate ty]:
	identifier  { $SymTab::symtab[$identifier.thetext] = $ty; } ('='   constant_expression)? ;
constant_expression returns [String rmId]:
	expression {$rmId = $expression.rmId; };

///////////////////////////////////////////////////////
field_declaration[TypeRepTemplate ty]:
	variable_declarators[$ty] ;
variable_declarators[TypeRepTemplate ty]:
	variable_declarator[ty] (','   variable_declarator[ty])* ;
variable_declarator[TypeRepTemplate ty]:
	identifier { $SymTab::symtab[$identifier.thetext] = $ty; } ('='   variable_initializer)? ;		// eg. event EventHandler IInterface.VariableName = Foo;

///////////////////////////////////////////////////////
method_declaration
scope SymTab;
@init {
    $SymTab::symtab = new Dictionary<string,TypeRepTemplate>();
}:
	method_header   method_body ;
method_header:
    ^(METHOD_HEADER attributes? modifiers? type member_name type_parameter_constraints_clauses? type_parameter_list? formal_parameter_list?);
method_body:
	block ;
member_name:
    type_or_generic ('.' type_or_generic)*
    //(type '.') => type '.' identifier 
    //| identifier
    ;
    // keving: missing interface_type.identifier
	//identifier ;		// IInterface<int>.Method logic added.

///////////////////////////////////////////////////////

event_declaration:
	'event'   type
		((member_name   '{') => member_name   '{'   event_accessor_declarations   '}'
		| variable_declarators[$type.dotNetType]   ';')	// typename=foo;
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
	parameter_modifier?   type   identifier  { $SymTab::symtab[$identifier.thetext] = $type.dotNetType; }  default_argument? ;
// 4.0
default_argument:
	'=' expression;
parameter_modifier:
	'ref' | 'out' | 'this' ;
parameter_array:
	^(p='params'   type   identifier { $SymTab::symtab[$identifier.thetext] = findType("System.Array", new TypeRepTemplate[] {$type.dotNetType}); }) ;


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
interface_member_declaration
scope SymTab;
@init {
    $SymTab::symtab = new Dictionary<string,TypeRepTemplate>();
}:
    ^(EVENT attributes? modifiers? event_declaration)
    | ^(METHOD attributes? modifiers? type identifier type_parameter_constraints_clauses? type_parameter_list? formal_parameter_list? exception*)
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

// rewrite to a method
conversion_operator_declaration[CommonTree atts, CommonTree mods]
scope SymTab;
@init {
    $SymTab::symtab = new Dictionary<string,TypeRepTemplate>();
    String methodName = "__cast";
}:
	h=conversion_operator_declarator 
        { 
            $SymTab::symtab[$h.var] = $h.varTy; 
            // if varTy is same as this class then need to include toType in methodname
            if ($NSContext::currentNS == $h.varTy.TypeName) 
            {
                methodName += $h.toTy.Java;
            }
        }  
    b=operator_body meth=magicCastOperator[$mods, methodName, $h.tree, $b.tree] -> $meth;
conversion_operator_declarator returns [ String var, TypeRepTemplate varTy, TypeRepTemplate toTy ] :
	('implicit' | 'explicit')  o='operator'   t=type   '('   f=type   n=identifier   ')' 
          { $var = $n.thetext; $varTy = $f.dotNetType; $toTy = $t.dotNetType; } 
      -> $o $t $f $n;
operator_body:
	block ;

///////////////////////////////////////////////////////
invocation_expression:
	invocation_start   (((arguments   ('['|'.'|'->')) => arguments   invocation_part)
						| invocation_part)*   arguments ;
invocation_start returns [TypeRepTemplate dotNetType]:
	predefined_type { $dotNetType = $predefined_type.dotNetType; }
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
    | switch_statement
	| iteration_statement	// while, do, for, foreach
	| jump_statement		// break, continue, goto, return, throw
	| ^('try' block catch_clauses? finally_clause?)
	| checked_statement
	| unchecked_statement
	| lock_statement
	| yield_statement 
    | ^('unsafe'   block)
	| fixed_statement
	| expression_statement	// expression!
	;
switch_statement
scope {
    bool isEnum;
    bool convertToIfThenElse;
    string scrutVar;
    bool isFirstCase;
}
@init {
    $switch_statement::isEnum = false;
    $switch_statement::convertToIfThenElse = false;
    $switch_statement::scrutVar = "WHOOPS";
    $switch_statement::isFirstCase = true;
}:
    ^(s='switch' se=expression sv=magicScrutineeVar[$s.token]
                { 
                    if ($expression.dotNetType != null) {
                        $switch_statement::isEnum = $expression.dotNetType.IsA(AppEnv.Search("System.Enum"), AppEnv); 
                        $switch_statement::convertToIfThenElse = typeIsInvalidForScrutinee($expression.dotNetType);
                        $switch_statement::scrutVar = $sv.thetext;
                    }
                } 
            ss+=switch_section*) 
        -> { $switch_statement::convertToIfThenElse }?
                // TODO: down the line, check if scrutinee is already a var and reuse that.
                // TYPE{ String } ret ;
                ^(TYPE[$s.token, "TYPE"] IDENTIFIER[$s.token,$expression.dotNetType.Java]) $sv ASSIGN[$s.token, "="] { dupTree($se.tree) } SEMI[$s.token, ";"]
        { convertSectionsToITE($ss) } 
        -> ^($s expression $ss*) 
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
	local_variable_type   local_variable_declarators[$local_variable_type.dotNetType] ;
local_variable_type returns [TypeRepTemplate dotNetType]:
	('var') => 'var'             { $dotNetType = new UnknownRepTemplate("System.Object"); }
	| ('dynamic') => 'dynamic'   { $dotNetType = new UnknownRepTemplate("System.Object"); }
	| type                       { $dotNetType = $type.dotNetType; };
local_variable_declarators[TypeRepTemplate ty]:
	local_variable_declarator[$ty] (',' local_variable_declarator[$ty])* ;
local_variable_declarator[TypeRepTemplate ty]:
	identifier { $SymTab::symtab[$identifier.thetext] = $ty; } ('='   local_variable_initializer)? ; 
local_variable_initializer:
	expression
	| array_initializer 
	| stackalloc_initializer;
stackalloc_initializer:
	'stackalloc'   unmanaged_type   '['   expression   ']' ;
local_constant_declaration:
	'const'   type   constant_declarators[$type.dotNetType] ;
expression_statement:
	expression   ';' ;

// TODO: should be assignment, call, increment, decrement, and new object expressions
statement_expression:
	expression
	;
else_statement:
	'else'   embedded_statement	;
switch_section
@init {
    bool defaultSection = false;
}
@after{
    $switch_statement::isFirstCase = false;
}:
	^(s=SWITCH_SECTION ({$switch_statement::convertToIfThenElse}? ite_switch_labels | switch_labels) sl=statement_list) 
      {
            
        }  
    -> {$switch_statement::convertToIfThenElse && $switch_statement::isFirstCase && $ite_switch_labels.isDefault}? { stripFinalBreak($sl.tree) }
    -> {$switch_statement::convertToIfThenElse && $ite_switch_labels.isDefault}? ELSE[$s.token, "else"]  OPEN_BRACE[$s.token, "{"] { stripFinalBreak($sl.tree) } CLOSE_BRACE[$s.token, "}"] 
    -> {$switch_statement::convertToIfThenElse && $switch_statement::isFirstCase}? ^(IF[$s.token, "if"]  ite_switch_labels SEP OPEN_BRACE[$s.token, "{"] { stripFinalBreak($sl.tree) } CLOSE_BRACE[$s.token, "}"])
    -> {$switch_statement::convertToIfThenElse}? ELSE[$s.token, "else"] ^(IF[$s.token, "if"]  ite_switch_labels SEP OPEN_BRACE[$s.token, "{"] { stripFinalBreak($sl.tree) } CLOSE_BRACE[$s.token, "}"])
    -> ^($s switch_labels statement_list)
    ;

ite_switch_labels returns [bool isDefault]
@init {
    $isDefault = false;
}:
        (l1=switch_label { if($l1.isDefault) $isDefault = true; } -> $l1)
        (ln=switch_label { if($ln.isDefault) $isDefault = true; } -> ^(LOG_OR[$ln.tree.Token, "||"] { dupTree($ite_switch_labels.tree) }  { dupTree($ln.tree) }) )*
    ;
switch_labels returns [bool isDefault]
@init {
    $isDefault = false;
}:
        switch_label+
    ;

switch_label returns [bool isDefault]
@init {
    $isDefault = false;
}:
    ^(c='case'  ce=constant_expression ) 
        -> { $switch_statement::convertToIfThenElse }? 
               // scrutVar.equals(ce)
               ^(APPLY[$c.token, "APPLY"] ^(DOT[$c.token, "."] IDENTIFIER[$c.token, $switch_statement::scrutVar] IDENTIFIER[$c.token, "equals"]) ^(ARGS[$c.token, "ARGS"] $ce))
        -> { $switch_statement::isEnum && $constant_expression.rmId != null}? ^($c IDENTIFIER[$c.token, $constant_expression.rmId])
        -> ^($c $ce)
	| 'default' { $isDefault = true; };
iteration_statement
scope SymTab;
@init {
    $SymTab::symtab = new Dictionary<string,TypeRepTemplate>();
    CommonTree ret = null;
    CommonTree newType = null;
    CommonTree newIdentifier = null;
    CommonTree newExpression = null;
    CommonTree newEmbeddedStatement = null;
}
@after {
    if (ret != null)
        $iteration_statement.tree = ret;
}:
	^('while' boolean_expression SEP embedded_statement)
	| do_statement
	| ^('for' for_initializer? SEP for_condition? SEP for_iterator? SEP embedded_statement)
	| ^(f='foreach' local_variable_type   identifier expression s=SEP  { $SymTab::symtab[$identifier.thetext] = $local_variable_type.dotNetType; }  embedded_statement)
           magicObjectType[$f.token] magicForeachVar[$f.token]
        {
            newType = $local_variable_type.tree;
            newIdentifier = $identifier.tree;
            newExpression = $expression.tree;
            newEmbeddedStatement = $embedded_statement.tree;
            TypeRepTemplate exprType = $expression.dotNetType;
            TypeRepTemplate elType = null;
            // translate expression, if available
            if (exprType != null) {
                ResolveResult iterable = exprType.ResolveIterable(AppEnv);
                if (iterable != null) {
                    Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                    myMap["expr"] = wrapExpression($expression.tree, $expression.tree.Token);
                    newExpression = mkJavaWrapper(iterable.Result.Java, myMap, $expression.tree.Token);
                    Imports.Add(iterable.Result.Imports);
                    elType = iterable.ResultType;
                }
            }
            bool needCast = true;
            if (elType != null && $local_variable_type.dotNetType != null) {
                if (elType.IsA($local_variable_type.dotNetType, AppEnv)) {
                    needCast = false;
                }
            } 
            // Construct new foreach using newExpression and needCast
            if (needCast) {
                newType = $magicObjectType.tree;
                newIdentifier = $magicForeachVar.tree;
                newEmbeddedStatement = prefixCast($local_variable_type.tree, $identifier.tree, mkBoxedType($local_variable_type.tree, $local_variable_type.tree.Token), newIdentifier, $embedded_statement.tree, $embedded_statement.tree.Token);
            }
        }
        -> ^($f { newType } { newIdentifier } { newExpression }  $s { newEmbeddedStatement })
    ;
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
catch_clause
scope SymTab;
@init {
    $SymTab::symtab = new Dictionary<string,TypeRepTemplate>();
}:
	^('catch' class_type   identifier { $SymTab::symtab[$identifier.thetext] = $class_type.dotNetType; } block) ;
finally_clause:
	^('finally'   block) ;
checked_statement:
	'checked'   block ;
unchecked_statement:
	'unchecked'   block ;
lock_statement:
	'lock'   '('  expression   ')'   embedded_statement ;
yield_statement:
	'yield'   ('return'   expression   ';'
	          | 'break'   ';') ;

///////////////////////////////////////////////////////
//	Lexar Section
///////////////////////////////////////////////////////

predefined_type returns [TypeRepTemplate dotNetType]
@init {
    string ns = "";
}
@after {
    $dotNetType = new ClassRepTemplate((ClassRepTemplate)AppEnv.Search(ns));
    $dotNetType.IsUnboxedType = true;
}:
	  'bool'    { ns = "System.Boolean"; }
    | 'byte'    { ns = "System.Byte"; }
    | 'char'    { ns = "System.Char"; }
    | 'decimal' { ns = "System.Decimal"; }
    | 'double'  { ns = "System.Double"; }
    | 'float'   { ns = "System.Single"; }
    | 'int'     { ns = "System.Int32"; }
    | 'long'    { ns = "System.Int64"; }
    | 'object'  { ns = "System.Object"; }
    | 'sbyte'   { ns = "System.SByte"; }
	| 'short'   { ns = "System.Int16"; }
    | 'string'  { ns = "System.String"; }
    | 'uint'    { ns = "System.UInt32"; }
    | 'ulong'   { ns = "System.UInt64"; }
    | 'ushort'  { ns = "System.UInt16"; }
    ;

// Don't trust identifier.text in tree grammars: Doesn't work for our magic additions because the text function goes back to the 
// original token stream to make up the text for a tree node 
identifier returns [String thetext]:
 	IDENTIFIER { $thetext = $IDENTIFIER.text; } | also_keyword { $thetext = $also_keyword.text; };  // might need to return text from also_keyword too if we start manufacturing those  

keyword:
	'abstract' | 'as' | 'base' | 'bool' | 'break' | 'byte' | 'case' |  'catch' | 'char' | 'checked' | 'class' | 'const' | 'continue' | 'decimal' | 'default' | 'delegate' | 'do' |	'double' | 'else' |	 'enum'  | 'event' | 'explicit' | 'extern' | 'false' | 'finally' | 'fixed' | 'float' | 'for' | 'foreach' | 'goto' | 'if' | 'implicit' | 'in' | 'int' | 'interface' | 'internal' | 'is' | 'lock' | 'long' | 'namespace' | 'new' | 'null' | 'object' | 'operator' | 'out' | 'override' | 'params' | 'private' | 'protected' | 'public' | 'readonly' | 'ref' | 'return' | 'sbyte' | 'sealed' | 'short' | 'sizeof' | 'stackalloc' | 'static' | 'string' | 'struct' | 'switch' | 'this' | 'throw' | 'true' | 'try' | 'typeof' | 'uint' | 'ulong' | 'unchecked' | 'unsafe' | 'ushort' | 'using' | 'virtual' | 'void' | 'volatile' ;

also_keyword:
	'add' | 'alias' | 'assembly' | 'module' | 'field' | 'method' | 'param' | 'property' | 'type' | 'yield'
	| 'from' | 'into' | 'join' | 'on' | 'where' | 'orderby' | 'group' | 'by' | 'ascending' | 'descending' 
	| 'equals' | 'select' | 'pragma' | 'let' | 'remove' | 'get' | 'set' | 'var' | '__arglist' | 'dynamic' | 'elif' 
	| 'endif' | 'define' | 'undef';

literal returns [TypeRepTemplate dotNetType]
@init {
    string ns = "System.Object";
    bool isNull = false;
}
@after {
    TypeRepTemplate retTy = AppEnv.Search(ns);
    if (isNull) {
        retTy = new ClassRepTemplate((ClassRepTemplate)retTy);
        retTy.IsExplicitNull = true;
    }
    $dotNetType = retTy; 
}:
	Real_literal 
	| NUMBER                    { ns = "System.Int32"; }
	| LONGNUMBER                { ns = "System.Int64"; }
	| Hex_number
	| Character_literal         { ns = "System.Char"; }
	| STRINGLITERAL             { ns = "System.String"; }
	| Verbatim_string_literal   { ns = "System.String"; }
	| TRUE                      { ns = "System.Boolean"; }
	| FALSE                     { ns = "System.Boolean"; }
	| NULL                      { ns = "System.Object"; isNull = true; }
	;

magicScrutineeVar [IToken tok] returns [String thetext]
@init {
    $thetext = "__dummyScrutVar" + dummyScrutVarCtr++;
}:
  -> IDENTIFIER[tok,$thetext];

magicForeachVar [IToken tok] returns [String thetext]
@init {
    $thetext = "__dummyForeachVar" + dummyForeachVarCtr++;
}:
  -> IDENTIFIER[tok,$thetext];

magicObjectType [IToken tok]:
  -> ^(TYPE[tok, "TYPE"] OBJECT[tok, "Object"]);

magicCastOperator[CommonTree mods, String methodName, CommonTree header, CommonTree body]
@init {
    IToken tok = ((CommonTree)$header.Children[0]).Token;
    CommonTree toType = dupTree((CommonTree)$header.Children[1]);
    CommonTree fromType = dupTree((CommonTree)$header.Children[2]);
    CommonTree paramName = dupTree((CommonTree)$header.Children[3]);
}:
->     ^(METHOD[tok, "METHOD"]
       { dupTree($mods) } 
       { toType } IDENTIFIER[tok, $methodName] ^(PARAMS[tok, "PARAMS"] { fromType } { paramName}) 
       { dupTree(body) }
      EXCEPTION[tok, "Throwable"])
;
