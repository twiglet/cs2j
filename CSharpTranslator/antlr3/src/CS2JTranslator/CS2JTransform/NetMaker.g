/*
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

tree grammar NetMaker;

options {
    tokenVocab=cs;
    ASTLabelType=CommonTree;
	output=AST;
    language=CSharp2;
    superClass='Twiglet.CS2J.Translator.Transform.CommonWalker';
}

// A scope to keep track of the namespace search path available at any point in the program
scope NSContext {

    string currentNS;

    // all namespaces in scope
    List<string> namespaces;
    // all namespaces in all scopes
    List<string> globalNamespaces;

    // all typevariables in scope
    List<string> typeVariables;
    // all typevariables in all scopes
    List<string> globalTypeVariables;

    // Does this type implement ICollection?
    bool IsGenericICollection;
    string GenericICollectionTyVar;
    bool IsICollection;
}

// A scope to keep track of the mapping from variables to types
scope SymTab {
    Dictionary<string,TypeRepTemplate> symtab;
}

// When this scope is true, then generate equivalent Object types instead of primitive types
scope PrimitiveRep {
    bool primitiveTypeAsObject;
}

// When this scope is true, then strip generic arguments from types 
// (In Java the runtime doesn't know the generic types so e.g. instanceof Set<T> 
// must be just instanceof Set).
scope MkNonGeneric {
    bool scrubGenericArgs;
}

@namespace { Twiglet.CS2J.Translator.Transform }

@header
{
    using System;
	using System.Text;
    using Twiglet.CS2J.Translator.Utils;
	using Twiglet.CS2J.Translator.TypeRep;
    using Twiglet.CS2J.Translator;
}

@members
{
    // in_member_name is set while we are processing member_name. It stops type_or_generic from 
    // treating its input as a type (and translating it).
    // TODO: Decide what should really be done here with <type>.member_name
    private bool in_member_name = false;

    private string CompUnitName = null;

    // Initial namespace search path gathered in JavaMaker
    public List<string> SearchPath { get; set; }
    public List<string> AliasKeys { get; set; }
    public List<string> AliasNamespaces { get; set; }

    protected CommonTree mkImports() {
    
        CommonTree root = (CommonTree)adaptor.Nil;
        
        if (Imports != null) {
            string[] sortedImports = Imports.AsArray();
            Array.Sort(sortedImports);
            foreach (string imp in sortedImports) {
                adaptor.AddChild(root, (CommonTree)adaptor.Create(IMPORT, "import"));
                adaptor.AddChild(root, (CommonTree)adaptor.Create(PAYLOAD, imp));
            }
        }
        return root;

    }

    public override void AddToImports(string imp) {
        // Don't add import if its namespace is within our type
//       if (!imp.StartsWith($NSContext::currentNS+".")) {
        if (imp != null && (CompUnitName == null || CompUnitName.Length == 0 || !imp.StartsWith(NSPrefix(CompUnitName)))) { 
            Imports.Add(imp);
        }
  //      }
    }

    protected string ParentNameSpace {
        get {
            return ((NSContext_scope)$NSContext.ToArray()[1]).currentNS;
        }
    }

    protected TypeRepTemplate findType(string name) {
        if ($NSContext::globalTypeVariables.Contains(name)) {
            return new TypeVarRepTemplate(name);
        }
        return AppEnv.Search($NSContext::globalNamespaces, name, new UnknownRepTemplate(name));
    }

    protected TypeRepTemplate findType(string name, ICollection<TypeRepTemplate> args) {
        if (args == null || args.Count == 0) {
            return findType(name);
        }
        StringBuilder argNames = new StringBuilder();
        bool first = true;
        if (args != null && args.Count > 0) {
            argNames.Append("<");
            foreach (TypeRepTemplate sub in args) {
                if (!first) {
                    argNames.Append(", ");
                    first = false;
                }
                argNames.Append(sub.TypeName);
            }
            argNames.Append(">");
        }
        
        TypeRepTemplate tyRep = AppEnv.Search($NSContext::globalNamespaces, mkGenericTypeAlias(name, args != null ? args.Count : 0), new UnknownRepTemplate(name + argNames.ToString()));
        return (args != null && args.Count > 0 ? tyRep.Instantiate(args) : tyRep);
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

    private ClassRepTemplate stringType = null;

    protected ClassRepTemplate StringType {
        get {
            if (stringType == null) {
                stringType = (ClassRepTemplate)AppEnv.Search("System.String", new UnknownRepTemplate("System.String"));
            }
            return stringType;
        }
    }

    private ClassRepTemplate dateType = null;
    protected ClassRepTemplate DateType {
        get {
            if (dateType == null) {
                dateType = (ClassRepTemplate)AppEnv.Search("System.DateTime", new UnknownRepTemplate("System.DateTime"));
            }
            return dateType;
        }
    }

    private InterfaceRepTemplate iCollectionType = null;
    protected InterfaceRepTemplate ICollectionType {
        get {
            if (iCollectionType == null) {
                iCollectionType = (InterfaceRepTemplate)findType("System.Collections.ICollection");
            }
            return iCollectionType;
        }
    }

    private InterfaceRepTemplate genericICollectionType = null;
    protected InterfaceRepTemplate GenericICollectionType {
        get {
            if (genericICollectionType == null) {
                genericICollectionType = (InterfaceRepTemplate)findType("System.Collections.Generic.ICollection", new TypeRepTemplate[] {ObjectType});
            }
            return genericICollectionType;
        }
    }

    // Map of Java built in types to their object based equivalents
    Dictionary<string, string> primitive_to_object_type_map = new Dictionary<string, string>()
    {
        {"byte", "Byte"},
        {"short", "Short"},
        {"int", "Integer"},
        {"long", "Long"},
        {"float", "Float"},
        {"double", "Double"},
        {"boolean", "Boolean"},
        {"char", "Character"}
    };


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
            foreach (string var in varMap.Keys) {
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

    protected CommonTree wrapType(CommonTree t, IToken tok) {
        CommonTree root = (CommonTree)adaptor.Nil;
        root = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(JAVAWRAPPERTYPE, tok, "TYPE"), root);
        adaptor.AddChild(root, dupTree(t));

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

    protected CommonTree castToBoxedType(TypeRepTemplate ty, CommonTree exp, IToken tok) {
       if (!String.IsNullOrEmpty(ty.BoxExpressionTemplate)) {
          Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
          myMap["expr"] = wrapExpression(exp, tok);
          return mkJavaWrapper(ty.BoxExpressionTemplate, myMap, tok);
       }
       else {
          return dupTree(exp);
       }
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
    protected int dummyStaticConstructorCatchVarCtr = 0;
    protected int dummyTyVarCtr = 0;
    protected int dummyRefVarCtr = 0;
    protected int dummyVarCtr = 0;

    // It turns out that 'default:' doesn't have to be last in the switch statement, so
    // we need some jiggery pokery when converting to if-then-else.
    // If there was a default section then 'defaultTree' will be non-null and 'sections'
    // will have a null entry (the hole where the default section appeared).
    protected CommonTree convertSectionsToITE(List sections, CommonTree defaultTree) {
        CommonTree ret = null;
        if ((sections == null || sections.Count == 1) && defaultTree != null) {
           // We just had a default section, so emit it.
           ret = dupTree(defaultTree);
        }
        else if (sections != null) {
           int startidx = sections.Count - 2;
           if (defaultTree != null) {
              // must have at least if .. then .. else
              // wrap default in else { }
              IToken tok = defaultTree.Token;
              CommonTree root = (CommonTree)adaptor.Nil;
              adaptor.AddChild(root, (CommonTree)adaptor.Create(ELSE, tok, "else"));
              adaptor.AddChild(root, (CommonTree)adaptor.Create(OPEN_BRACE, tok, "{"));
              adaptor.AddChild(root, dupTree(defaultTree));
              adaptor.AddChild(root, (CommonTree)adaptor.Create(CLOSE_BRACE, tok, "}"));
              ret = root;
              startidx = sections.Count - 1;
           }
           else {
            ret = dupTree((CommonTree)sections[sections.Count - 1]);
           }
           for(int i = startidx; i >= 0; i--) {
              if (sections[i] != null) {
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

    private Dictionary<int,int> _assOpMap = null;
    protected Dictionary<int,int> AssOpMap {
        get {
            if (_assOpMap == null) {
                _assOpMap  = new Dictionary<int,int>();
                // Initialize boxTypeMap (see JLS, ed 3 sec 5.1.7)
                _assOpMap[PLUS_ASSIGN] = PLUS;
                _assOpMap[MINUS_ASSIGN] = MINUS;
                _assOpMap[STAR_ASSIGN] = STAR;
                _assOpMap[DIV_ASSIGN] = DIV;
                _assOpMap[MOD_ASSIGN] = MOD;
                _assOpMap[BIT_AND_ASSIGN] = BIT_AND;
                _assOpMap[BIT_OR_ASSIGN] = BIT_OR;
                _assOpMap[BIT_XOR_ASSIGN] = BIT_XOR;
                _assOpMap[LEFT_SHIFT_ASSIGN] = LEFT_SHIFT;
                _assOpMap[RIGHT_SHIFT_ASSIGN] = RIGHT_SHIFT;
            }
            return _assOpMap;
        }
    }
    
    protected CommonTree mkOpExp(CommonTree assTree) {
        CommonTree ret = assTree;
        if (AssOpMap.ContainsKey(assTree.Token.Type)) {
            ret = (CommonTree)adaptor.Create(AssOpMap[assTree.Token.Type], assTree.Token, assTree.Token.Text != null && assTree.Token.Text.EndsWith("=") ? assTree.Token.Text.Substring(0, assTree.Token.Text.Length - 1) : assTree.Token.Text);
        }
        return ret;
    }

    // make ^(op lhs rhs)
    protected CommonTree mkOpExp(CommonTree opTree, CommonTree lhs, CommonTree rhs) {
        CommonTree root = (CommonTree)adaptor.Nil;
        root = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.DupTree(opTree), root);
        adaptor.AddChild(root, (CommonTree)adaptor.DupTree(lhs));
        adaptor.AddChild(root, (CommonTree)adaptor.DupTree(rhs));
        return root;
    }

    protected CommonTree mkJavaRep(IToken tok, TypeRepTemplate ty) {
       if (ty.InstantiatedTypes.Length == 0) {
          return (CommonTree)adaptor.Create(IDENTIFIER, tok, ty.Java);
       }
       else {
          Dictionary<string,CommonTree> tyMap = new Dictionary<string,CommonTree>();
          int i = 0;
          foreach (TypeRepTemplate tyArg in ty.InstantiatedTypes) {
             CommonTree typeRoot = (CommonTree)adaptor.Nil;
             typeRoot = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(TYPE, tok, "TYPE"), typeRoot);
             adaptor.AddChild(typeRoot, mkJavaRep(tok, tyArg));
             tyMap[ty.TypeParams[i]] = wrapType(typeRoot, tok);
             i++;
          }
          return mkJavaWrapper(ty.Java, tyMap, tok);  
       } 
    }

    // either ^(PARAMS (type identifier)*) or ^(ARGS identifier*) depending on value of formal
    protected CommonTree mkParams(TypeRepTemplate tyRep, List<ParamRepTemplate> inParams, bool formal, IToken tok) {
        CommonTree root = (CommonTree)adaptor.Nil;
        root = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(formal ? PARAMS : ARGS, tok, formal ? "PARAMS" : "ARGS"), root);
        foreach (ParamRepTemplate p in inParams) {
           if (formal) {
              TypeRepTemplate ty = tyRep.BuildType(p.Type, AppEnv, new UnknownRepTemplate(p.Type));
              CommonTree typeRoot = (CommonTree)adaptor.Nil;
              typeRoot = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(TYPE, tok, "TYPE"), typeRoot);
              adaptor.AddChild(typeRoot, mkJavaRep(tok, ty));
              adaptor.AddChild(root, typeRoot);
              AddToImports(ty.Imports);
           }
           adaptor.AddChild(root, (CommonTree)adaptor.Create(IDENTIFIER, tok, p.Name));
        }
        return root;
    }

    // make ^(PARAMS (type identifier)*) from a List<ParamRepTemplate (for the types) and List<IDENTIFIER> for the names 
    protected CommonTree mkTypedParams(List<ParamRepTemplate> inParams, List<CommonTree> ids, IToken tok) {
        CommonTree root = (CommonTree)adaptor.Nil;
        root = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(PARAMS, tok, "PARAMS"), root);
        CommonTree[] idsArray = ids.ToArray();
        int i = 0;
        foreach (ParamRepTemplate p in inParams) {
           TypeRepTemplate ty = findType(p.Type);
           CommonTree typeRoot = (CommonTree)adaptor.Nil;
           typeRoot = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(TYPE, tok, "TYPE"), typeRoot);
           adaptor.AddChild(typeRoot, (CommonTree)adaptor.Create(IDENTIFIER, tok, ty.Java));
           adaptor.AddChild(root, typeRoot);
           AddToImports(ty.Imports);
           adaptor.AddChild(root, dupTree(idsArray[i]));
           i++;
        }
        return root;
    }

    //  public List<delegate_type> GetInvocationList() throws Exception {
    //        	List<delegate_type> ret = new ArrayList<delegate_type>();
    //        	ret.add(this);
    //          return ret;
    //   }
    protected CommonTree mkDelegateGetInvocationList(CommonTree delTree, TypeRepTemplate delType, IToken tok) {

//     | ^(METHOD attributes? modifiers? type member_name type_parameter_constraints_clauses? type_parameter_list? formal_parameter_list? method_body exception*)
        CommonTree method = (CommonTree)adaptor.Nil;
        method = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(METHOD, tok, "METHOD"), method);

        adaptor.AddChild(method, (CommonTree)adaptor.Create(PUBLIC, tok, "public"));

        CommonTree retTypeRoot = (CommonTree)adaptor.Nil;
        retTypeRoot = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(TYPE, tok, "TYPE"), retTypeRoot);
        adaptor.AddChild(retTypeRoot, (CommonTree)adaptor.Create(IDENTIFIER, tok, "List"));
        AddToImports("java.util.List");
        adaptor.AddChild(retTypeRoot, (CommonTree)adaptor.Create(LTHAN, tok, "<"));
        CommonTree delTypeRoot = (CommonTree)adaptor.Nil;
        if (delTree != null) {
           delTypeRoot = dupTree(delTree);
        }
        else {
           delTypeRoot = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(TYPE, tok, "TYPE"), delTypeRoot);
           adaptor.AddChild(delTypeRoot, (CommonTree)adaptor.Create(IDENTIFIER, tok, delType.mkFormattedTypeName(false, "<",">")));
           AddToImports(delType.Imports);
        }
        adaptor.AddChild(retTypeRoot, delTypeRoot);

        adaptor.AddChild(retTypeRoot, (CommonTree)adaptor.Create(GT, tok, ">"));

        adaptor.AddChild(method, retTypeRoot);

        adaptor.AddChild(method, (CommonTree)adaptor.Create(IDENTIFIER, tok, "GetInvocationList"));

        adaptor.AddChild(method, (CommonTree)adaptor.Create(OPEN_BRACE, tok, "{"));


        CommonTree body = (CommonTree)adaptor.Nil;

        // List<delegate_type> ret = new ArrayList<delegate_type>();
        CommonTree retdecl = (CommonTree)adaptor.Nil;

        adaptor.AddChild(retdecl, dupTree(retTypeRoot));
        adaptor.AddChild(retdecl, (CommonTree)adaptor.Create(IDENTIFIER, tok, "ret"));
        adaptor.AddChild(retdecl, (CommonTree)adaptor.Create(ASSIGN, tok, "="));

        CommonTree newA = (CommonTree)adaptor.Nil;
        newA = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(NEW, tok, "new"), newA);

        CommonTree alTypeRoot = (CommonTree)adaptor.Nil;
        alTypeRoot = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(TYPE, tok, "TYPE"), alTypeRoot);
        adaptor.AddChild(alTypeRoot, (CommonTree)adaptor.Create(IDENTIFIER, tok, "ArrayList"));
        AddToImports("java.util.ArrayList");
        adaptor.AddChild(alTypeRoot, (CommonTree)adaptor.Create(LTHAN, tok, "<"));
  
        adaptor.AddChild(alTypeRoot, dupTree(delTypeRoot));

        adaptor.AddChild(alTypeRoot, (CommonTree)adaptor.Create(GT, tok, ">"));

        adaptor.AddChild(newA, alTypeRoot);
        adaptor.AddChild(retdecl, newA);
        adaptor.AddChild(body, retdecl);
        adaptor.AddChild(body, (CommonTree)adaptor.Create(SEMI, tok, ";"));

        // ret.add(this)
        CommonTree retaddcall = (CommonTree)adaptor.Nil;
        retaddcall = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(APPLY, tok, "APPLY"), retaddcall);

        CommonTree retadd = (CommonTree)adaptor.Nil;
        retadd = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(DOT, tok, "."), retadd);
        adaptor.AddChild(retadd, (CommonTree)adaptor.Create(IDENTIFIER, tok, "ret"));
        adaptor.AddChild(retadd, (CommonTree)adaptor.Create(IDENTIFIER, tok, "add"));

        adaptor.AddChild(retaddcall, retadd);

        CommonTree arg = (CommonTree)adaptor.Nil;
        arg = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(ARGS, tok, "ARGS"), arg);

        adaptor.AddChild(arg, (CommonTree)adaptor.Create(THIS, tok, "this"));
        adaptor.AddChild(retaddcall, arg);
        adaptor.AddChild(body,retaddcall);
        adaptor.AddChild(body, (CommonTree)adaptor.Create(SEMI, tok, ";"));

        // return ret;
        CommonTree ret = (CommonTree)adaptor.Nil;
        ret = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(RETURN, tok, "return"), ret);
        adaptor.AddChild(ret, (CommonTree)adaptor.Create(IDENTIFIER, tok, "ret"));
        adaptor.AddChild(body,ret);

        adaptor.AddChild(method, body);

        adaptor.AddChild(method, (CommonTree)adaptor.Create(CLOSE_BRACE, tok, "}"));
        adaptor.AddChild(method, (CommonTree)adaptor.Create(EXCEPTION, tok, "Exception"));

        return method;
    }

    // new <delegate_type>() { public void Invoke(<formal args>) throws Exception { [return] arg[0](<args>); }
    //                         public List<delegate_type> GetInvocationList() throws Exception { ... }}
    protected CommonTree mkDelegateObject(CommonTree delTree, CommonTree methTree, DelegateRepTemplate delg, IToken tok) {
        CommonTree root = (CommonTree)adaptor.Nil;
        root = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(NEW_DELEGATE, tok, "NEW_DELEGATE"), root);
        if (delTree != null) {
           adaptor.AddChild(root, dupTree(delTree));
        }
        else {
           CommonTree delTyTree = (CommonTree)adaptor.Nil;
           delTyTree = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(TYPE, tok, "TYPE"), delTyTree);
           adaptor.AddChild(delTyTree, (CommonTree)adaptor.Create(IDENTIFIER, tok, delg.mkFormattedTypeName(false, "<",">")));
           AddToImports(delg.Imports);
           adaptor.AddChild(root, delTyTree);
        }

        adaptor.AddChild(root, (CommonTree)adaptor.Create(OPEN_BRACE, tok, "{"));

//     | ^(METHOD attributes? modifiers? type member_name type_parameter_constraints_clauses? type_parameter_list? formal_parameter_list? method_body exception*)
        CommonTree method = (CommonTree)adaptor.Nil;
        method = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(METHOD, tok, "METHOD"), method);

        adaptor.AddChild(method, (CommonTree)adaptor.Create(PUBLIC, tok, "public"));

        TypeRepTemplate returnType = findType(delg.Invoke.Return);
        AddToImports(returnType.Imports);
        CommonTree retTypeRoot = (CommonTree)adaptor.Nil;
        retTypeRoot = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(TYPE, tok, "TYPE"), retTypeRoot);
        adaptor.AddChild(retTypeRoot, (CommonTree)adaptor.Create(IDENTIFIER, tok, returnType.Java));
        adaptor.AddChild(method, retTypeRoot);

        adaptor.AddChild(method, (CommonTree)adaptor.Create(IDENTIFIER, tok, "Invoke"));
        if (delg.Invoke.Params.Count > 0) {
           adaptor.AddChild(method, mkParams(delg, delg.Invoke.Params, true, tok));
        }
        adaptor.AddChild(method, (CommonTree)adaptor.Create(OPEN_BRACE, tok, "{"));

        CommonTree ret = (CommonTree)adaptor.Nil;
        ret = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(RETURN, tok, "return"), ret);

        CommonTree call = (CommonTree)adaptor.Nil;
        call = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(APPLY, tok, "APPLY"), call);
        adaptor.AddChild(call, dupTree(methTree));
        if (delg.Invoke.Params.Count > 0) {
           adaptor.AddChild(call, mkParams(delg, delg.Invoke.Params, false, tok));
        }
        if (returnType.IsA(VoidType, AppEnv)) {
           adaptor.AddChild(ret, call);
           adaptor.AddChild(method, ret);
        }
        else {
           adaptor.AddChild(method, call);
           adaptor.AddChild(method, (CommonTree)adaptor.Create(SEMI, tok, ";"));
        }

        adaptor.AddChild(method, (CommonTree)adaptor.Create(CLOSE_BRACE, tok, "}"));
        adaptor.AddChild(method, (CommonTree)adaptor.Create(EXCEPTION, tok, "Exception"));
        adaptor.AddChild(root, method);
        adaptor.AddChild(root, mkDelegateGetInvocationList(delTree, delg, tok));

        adaptor.AddChild(root, (CommonTree)adaptor.Create(CLOSE_BRACE, tok, "}"));

        return root;
    }

    // new <delegate_type>() { public void Invoke(<formal args>) throw exception <body> }
    protected CommonTree mkDelegateObject(CommonTree delTree, CommonTree argsTree, CommonTree bodyTree, DelegateRepTemplate delg, IToken tok) {
        CommonTree root = (CommonTree)adaptor.Nil;
        root = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(NEW_DELEGATE, tok, "NEW_DELEGATE"), root);
        if (delTree != null) {
           adaptor.AddChild(root, dupTree(delTree));
        }
        else {
           CommonTree delTyTree = (CommonTree)adaptor.Nil;
           delTyTree = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(TYPE, tok, "TYPE"), delTyTree);
           adaptor.AddChild(delTyTree, (CommonTree)adaptor.Create(IDENTIFIER, tok, delg.mkFormattedTypeName(false, "<",">")));
           AddToImports(delg.Imports);
           adaptor.AddChild(root, delTyTree);
        }

        adaptor.AddChild(root, (CommonTree)adaptor.Create(OPEN_BRACE, tok, "{"));

//     | ^(METHOD attributes? modifiers? type member_name type_parameter_constraints_clauses? type_parameter_list? formal_parameter_list? method_body exception*)
        CommonTree method = (CommonTree)adaptor.Nil;
        method = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(METHOD, tok, "METHOD"), method);

        adaptor.AddChild(method, (CommonTree)adaptor.Create(PUBLIC, tok, "public"));

        TypeRepTemplate returnType = findType(delg.Invoke.Return);
        AddToImports(returnType.Imports);
        CommonTree retTypeRoot = (CommonTree)adaptor.Nil;
        retTypeRoot = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(TYPE, tok, "TYPE"), retTypeRoot);
        adaptor.AddChild(retTypeRoot, (CommonTree)adaptor.Create(IDENTIFIER, tok, returnType.Java));
        adaptor.AddChild(method, retTypeRoot);

        adaptor.AddChild(method, (CommonTree)adaptor.Create(IDENTIFIER, tok, "Invoke"));
        adaptor.AddChild(method, dupTree(argsTree));
        adaptor.AddChild(method, dupTree(bodyTree));
        adaptor.AddChild(method, (CommonTree)adaptor.Create(EXCEPTION, tok, "Exception"));
        adaptor.AddChild(root, method);
        adaptor.AddChild(root, mkDelegateGetInvocationList(delTree, delg, tok));

        adaptor.AddChild(root, (CommonTree)adaptor.Create(CLOSE_BRACE, tok, "}"));

        return root;
    }

}

public compilation_unit
scope NSContext, PrimitiveRep, MkNonGeneric;
@init {

    $PrimitiveRep::primitiveTypeAsObject = false;
    $MkNonGeneric::scrubGenericArgs = false;

    // TODO: Do we need to ensure we have access to System? If so, can add it here.
    $NSContext::namespaces = SearchPath ?? new List<string>();
    $NSContext::globalNamespaces = SearchPath ?? new List<string>();

    $NSContext::typeVariables = new List<string>();
    $NSContext::globalTypeVariables = new List<string>();

    $NSContext::IsGenericICollection = false;
    $NSContext::GenericICollectionTyVar = "";
    $NSContext::IsICollection = false;

}:
	^(pkg=PACKAGE ns=PAYLOAD { $NSContext::currentNS = $ns.text; } dec=type_declaration  )
    -> ^($pkg $ns  { mkImports() } $dec);

type_declaration:
	class_declaration
	| interface_declaration
	| enum_declaration
   ;
// Identifiers
qualified_identifier:
	identifier ('.' identifier)*;

modifiers returns [List<string> modList]
@init {
    $modList = new List<string>();
}:
	(modifier { $modList.Add($modifier.tree.Text); } )+ ;
modifier: 
	'new' | 'public' | 'protected' | 'private' | 'abstract' | 'sealed' | 'static'
	| 'readonly' | 'volatile' | 'extern' | 'virtual' | 'override' | FINAL ;
	
class_member_declaration:
    ^(CONST attributes? modifiers? type constant_declarators[$type.dotNetType])
    | ^(EVENT attributes? modifiers? event_declaration)
    | ^(METHOD attributes? modifiers? type member_name type_parameter_constraints_clauses? type_parameter_list? formal_parameter_list? method_body exception*)
    | interface_declaration
    | class_declaration
    | ^(FIELD attributes? modifiers? type field_declaration[$type.tree, $type.dotNetType])
    | ^(OPERATOR attributes? modifiers? type operator_declaration)
    | enum_declaration
    | ^(CONVERSION_OPERATOR attributes? modifiers? conversion_operator_declaration[$attributes.tree, $modifiers.tree]) -> conversion_operator_declaration
    | constructor_declaration
    ;

exception:
    EXCEPTION;

constructor_declaration
@init {
   bool isStatic = false;
}:
    ^(c=CONSTRUCTOR attributes? (modifiers { isStatic = $modifiers.modList.Contains("static"); })? identifier  formal_parameter_list? block exception* sb=magicSmotherExceptionsThrow[$block.tree, "ExceptionInInitializerError"])
      -> { isStatic }? ^(STATIC_CONSTRUCTOR[$c.token, "CONSTRUCTOR"] attributes? modifiers? $sb)
      ->  ^($c attributes? modifiers? identifier formal_parameter_list? block exception*)
       ;



// rmId is the rightmost ID in an expression like fdfd.dfdsf.returnme, otherwise it is null
// used in switch labels to strip down qualified types, which Java doesn't grok
// thedottedtext is the text read so far that *might* be part of a qualified type  
primary_expression[TypeRepTemplate typeCtxt] returns [TypeRepTemplate dotNetType, string rmId, TypeRepTemplate typeofType, string thedottedtext]
scope {
    bool parentIsApply;
}
@init {
    $primary_expression::parentIsApply = false;
    CommonTree ret = null;
    TypeRepTemplate expType = SymTabLookup("this");
    bool implicitThis = true;
    $thedottedtext = null;
    string popstr = null;
    CommonTree e1Tree = null;
}
@after {
    if (ret != null)
        $primary_expression.tree = ret;
}:
    ^(index=INDEX ie=expression[ObjectType] expression_list?)
        {
            expType = $ie.dotNetType ?? (new UnknownRepTemplate("INDEXER.BASE"));
            if (expType.IsUnknownType) {
               WarningFailedResolve($index.token.Line, "Could not find type of indexed expression");
            }
            $dotNetType = new UnknownRepTemplate(expType.TypeName+".INDEXER");
            ResolveResult indexerResult = expType.ResolveIndexer($expression_list.expTypes ?? new List<TypeRepTemplate>(), AppEnv);
            if (indexerResult != null) {
               if (!String.IsNullOrEmpty(indexerResult.Result.Warning)) Warning($index.line, indexerResult.Result.Warning);
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
                  AddToImports(indexerResult.Result.Imports);
                  $dotNetType = indexerResult.ResultType; 
               }
            }
            else {
               WarningFailedResolve($index.token.Line, "Could not resolve index expression against " + expType.TypeName);
            }
        }
    | (^(APPLY (^('.' expression[ObjectType] identifier generic_argument_list?)|(identifier generic_argument_list?)) argument_list?)) => 
           ^(APPLY (^(d0='.' e2=expression[ObjectType] {expType = $e2.dotNetType; implicitThis = false;} i2=identifier generic_argument_list?)|(i2=identifier generic_argument_list?)) argument_list?)
        {
            if (implicitThis && SymTabLookup($i2.thetext) != null) {
               // we have a local var with a delegate reference (I hope ...)?
               DelegateRepTemplate idType = SymTabLookup($i2.thetext) as DelegateRepTemplate;
               if (idType != null) {
                  Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                  myMap["this"] = wrapExpression($i2.tree, $i2.tree.Token);
                  for (int idx = 0; idx < idType.Invoke.Params.Count; idx++) {
                     myMap[idType.Invoke.Params[idx].Name] = wrapArgument($argument_list.argTrees[idx], $i2.tree.Token);
                     if (idType.Invoke.Params[idx].Name.StartsWith("TYPEOF") && $argument_list.argTreeTypeofTypes[idx] != null) {
                        // if this argument is a typeof expression then add a TYPEOF_TYPEOF-> typeof's type mapping
                        myMap[idType.Invoke.Params[idx].Name + "_TYPE"] = wrapTypeOfType($argument_list.argTreeTypeofTypes[idx], $i2.tree.Token);
                     }
                  }
                  AddToImports(idType.Invoke.Imports);
                  ret = mkJavaWrapper(idType.Invoke.Java, myMap, $i2.tree.Token);
                  $dotNetType = AppEnv.Search(idType.Invoke.Return);
               }
            }
            else {

               if (expType == null) {
                  expType = new UnknownRepTemplate("APPLY.BASE");
               }
               if (expType.IsUnknownType) {
                  WarningFailedResolve($i2.tree.Token.Line, "Could not find type needed to resolve method application");
               }
               $dotNetType = new UnknownRepTemplate(expType.TypeName+".APPLY");
               ResolveResult calleeResult = expType.Resolve($i2.thetext, $argument_list.argTypes ?? new List<TypeRepTemplate>(), AppEnv);
               if (calleeResult != null) {
                  if (!String.IsNullOrEmpty(calleeResult.Result.Warning)) Warning($d0.line, calleeResult.Result.Warning);
                  DebugDetail($i2.tree.Token.Line + ": Found '" + $i2.thetext + "'");
                  
                  // We are calling a method or a delegate on an expression. If it has a primitive type then cast it to 
                  // the appropriate Object type.
                  CommonTree e2InBox = expType.IsUnboxedType && Cfg.ExperimentalTransforms ? castToBoxedType(expType, $e2.tree, $d0.token) : $e2.tree;
                  Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                  MethodRepTemplate calleeMethod = null;
                  
                  if (calleeResult is DelegateResolveResult) {
                     // We have a field/property that is pointing at a delegate, first extract the delegate ...
                    Dictionary<string,CommonTree> delMap = new Dictionary<string,CommonTree>();
                    if (!implicitThis) {
                       delMap["this"] = wrapExpression(e2InBox, $i2.tree.Token);
                    }
                    myMap["this"] = mkJavaWrapper(calleeResult.Result.Java, delMap, $i2.tree.Token);
                    AddToImports(calleeResult.Result.Imports);
                    calleeMethod = ((DelegateRepTemplate)((DelegateResolveResult)calleeResult).DelegateResult.Result).Invoke;
                  }
                  else {  
                     if (!implicitThis) {
                        myMap["this"] = wrapExpression(e2InBox, $i2.tree.Token);
                     }
                    calleeMethod = calleeResult.Result as MethodRepTemplate;
                  }

                  for (int idx = 0; idx < calleeMethod.Params.Count; idx++) {
                     myMap[calleeMethod.Params[idx].Name] = wrapArgument($argument_list.argTrees[idx], $i2.tree.Token);
                     if (calleeMethod.Params[idx].Name.StartsWith("TYPEOF") && $argument_list.argTreeTypeofTypes[idx] != null) {
                        // if this argument is a typeof expression then add a TYPEOF_TYPEOF-> typeof's type mapping
                        myMap[calleeMethod.Params[idx].Name + "_TYPE"] = wrapTypeOfType($argument_list.argTreeTypeofTypes[idx], $i2.tree.Token);
                     }
                  }
                  ret = mkJavaWrapper(calleeMethod.Java, myMap, $i2.tree.Token);
                  AddToImports(calleeMethod.Imports);
                  $dotNetType = calleeResult.ResultType; 
               }
               else {
                  WarningFailedResolve($i2.tree.Token.Line, "Could not resolve method application of " + $i2.thetext + " against " + expType.TypeName);
               }
            }
        }
    | ^(APPLY {$primary_expression::parentIsApply = true; } expression[ObjectType] {$primary_expression::parentIsApply = false; } argument_list?)
    | (^((POSTINC|POSTDEC) (^('.' expression[objectType] identifier) | identifier))) =>
      (^(POSTINC {popstr = "+";} (^('.' pse=expression[ObjectType] pi=identifier {implicitThis = false;}) | pi=identifier))
      | ^(POSTDEC {popstr = "-";} (^('.' pse=expression[ObjectType] pi=identifier {implicitThis = false;}) | pi=identifier)))
      {
            if (implicitThis && SymTabLookup($pi.thetext) != null) {
               // Is this a wrapped parameter?
               TypeRepTemplate idType = SymTabLookup($pi.thetext);
               if (idType.IsWrapped) {
                  Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                  myMap["this"] = wrapExpression($pi.tree, $pi.tree.Token);
                  AddToImports("CS2JNet.JavaSupport.language.ReturnPreOrPostValue");
                  ret = mkJavaWrapper("${this}.setValue(${this}.getValue() " + popstr + " 1, ReturnPreOrPostValue.POST)", myMap, $pi.tree.Token);
                }
                $dotNetType = idType;
               // a simple variable 
            }
            else {
               TypeRepTemplate seType = (implicitThis ? SymTabLookup("this") : $pse.dotNetType);
               if (seType == null) {
                  seType = new UnknownRepTemplate("FIELD.BASE");
               }
               if (seType.IsUnknownType) {
                  WarningFailedResolve($pi.tree.Token.Line, "Could not find type of expression for field /property access");
               }
               ResolveResult fieldResult = seType.Resolve($pi.thetext, true, AppEnv);
               if (fieldResult != null) {
                  if (!String.IsNullOrEmpty(fieldResult.Result.Warning)) Warning($pi.tree.Token.Line, fieldResult.Result.Warning);
                  if (fieldResult.Result is PropRepTemplate) {
                     PropRepTemplate propRep = fieldResult.Result as PropRepTemplate;
                     if (!String.IsNullOrEmpty(propRep.JavaSet)) {
                        // only translate if we also have JavaGet  

                        // We have to resolve property reads and writes separately, because they may come from 
                        // different parent classes
                        ResolveResult readFieldResult = seType.Resolve($pi.thetext, false, AppEnv);
                        if (readFieldResult.Result is PropRepTemplate) {
                           if (!String.IsNullOrEmpty(readFieldResult.Result.Warning)) Warning($pi.tree.Token.Line, readFieldResult.Result.Warning);
                           PropRepTemplate readPropRep = readFieldResult.Result as PropRepTemplate;

                           if (!String.IsNullOrEmpty(readPropRep.JavaGet)) {
                              // we have prop (++/--)
                              // need to translate to setProp(getProp (+/-) 1)
                              Dictionary<string,CommonTree> rhsMap = new Dictionary<string,CommonTree>();
                              if (!implicitThis)
                                 rhsMap["this"] = wrapExpression($pse.tree, $pi.tree.Token);
                              CommonTree rhsPropTree = mkJavaWrapper(readPropRep.JavaGet, rhsMap, $pi.tree.Token);
                              CommonTree newRhsExp = (CommonTree)adaptor.Nil;
                              newRhsExp = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(popstr == "+" ? PLUS : MINUS, $pi.tree.Token, popstr), newRhsExp);
                              adaptor.AddChild(newRhsExp, (CommonTree)adaptor.DupTree(rhsPropTree));
                              adaptor.AddChild(newRhsExp, (CommonTree)adaptor.Create(NUMBER,$pi.tree.Token, "1"));

                              Dictionary<string,CommonTree> valMap = new Dictionary<string,CommonTree>();
                              if (!implicitThis)
                                 valMap["this"] = wrapExpression($pse.tree, $pi.tree.Token);
                              valMap["value"] = wrapExpression(newRhsExp, $pi.tree.Token);
                              ret = mkJavaWrapper(propRep.JavaSet, valMap, $pi.tree.Token);
                              AddToImports(propRep.Imports);
                           }
                        }
                     }
                  }
               }
               else {
                  WarningFailedResolve($pi.tree.Token.Line, "Could not resolve field or property expression against " + seType.ToString());
               }
            }
      }
    | ^(POSTINC expression[ObjectType])    { $dotNetType = $expression.dotNetType; }
    | ^(POSTDEC expression[ObjectType])    { $dotNetType = $expression.dotNetType; }
    | ^('->' expression[ObjectType] identifier generic_argument_list?)
	| predefined_type                                                { $dotNetType = $predefined_type.dotNetType; }         
	| 'this'                                                         { $dotNetType = SymTabLookup("this"); }         
	| SUPER                                                          { $dotNetType = SymTabLookup("super"); }         
    | (^(d1='.' e1=expression[ObjectType] {expType = $e1.dotNetType; implicitThis = false; e1Tree = dupTree($e1.tree); /* keving: yuk, shouldn't be necessary but $e1.tree was also capturing i=identifier */} i=identifier dgal=generic_argument_list?)
        |(i=identifier dgal=generic_argument_list?))  magicInputPeId[$d1.tree,$i.tree,$dgal.tree]
        { 
            // TODO: generic_argument_list is ignored ....

            // Possibilities:
            // - a variable in scope.
            // - a property/field of some object
            // - a type name
            // - a method name if we are in a delegate type context then create a delegate (in C# it is an implicit cast) 
            // - part of a type name
            bool found = false;
            if (implicitThis) {
               // single identifier, might be a variable
               TypeRepTemplate idType = SymTabLookup($i.thetext);
               if (idType != null) {
                  // Is this a wrapped parameter?
                  if (idType.IsWrapped) {
                     Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                     myMap["this"] = wrapExpression($i.tree, $i.tree.Token);
                     ret = mkJavaWrapper("${this}.getValue()", myMap, $i.tree.Token);
                  }
                  $dotNetType = idType;
                  found = true;
               }
            }
            if (!found) {
                // Not a variable, expType is the type of 'expression', or 'this'.

                // Is it a property read? Ensure we are not being applied to arguments or about to be assigned
                if (expType != null && !expType.IsUnknownType &&
                    ($primary_expression.Count == 1 || !((primary_expression_scope)($primary_expression.ToArray()[1])).parentIsApply)) {
                    
                    DebugDetail($i.tree.Token.Line + ": '" + $i.thetext + "' might be a property");
                    ResolveResult fieldResult = expType.Resolve($i.thetext, false, AppEnv);
                    if (fieldResult != null) {
                       if (!String.IsNullOrEmpty(fieldResult.Result.Warning)) Warning($i.tree.Token.Line, fieldResult.Result.Warning);
                        DebugDetail($i.tree.Token.Line + ": Found '" + $i.thetext + "'");

                        Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                        if (!implicitThis) {
                           // We are accessing a field / property on an expression. If it has a primitive type then cast it to 
                           // the appropriate Object type.
                           CommonTree e1InBox = expType.IsUnboxedType && Cfg.ExperimentalTransforms ? castToBoxedType(expType, e1Tree, $d1.token) : e1Tree;
                           myMap["this"] = wrapExpression(e1InBox, $i.tree.Token);
                        }
                        ret = mkJavaWrapper(fieldResult.Result.Java, myMap, $i.tree.Token);
                        AddToImports(fieldResult.Result.Imports);
                        $dotNetType = fieldResult.ResultType; 
                        found = true;
                    }
                }
            }
            if (!found && (implicitThis || $e1.thedottedtext != null)) {
                String textSoFar = (implicitThis ? "" : $e1.thedottedtext + ".") + $i.thetext;
                // Not a variable, not a property read, is it a type name?
                TypeRepTemplate staticType = findType(textSoFar);
                if (!staticType.IsUnknownType) {
                    AddToImports(staticType.Imports);
                    $dotNetType = staticType;
                    found = true;
                }
            }
            if (!found) {
               // Could be a reference to a method group. If we are in a Delegate Type context then create a delegate object.
               if ($typeCtxt != null && $typeCtxt is DelegateRepTemplate) {
                  // Since 'type' is a delegate then we assume that argument_list[0] will be a method group name.
                  // use an anonymous inner class to generate a delegate object (object wih an Invoke with appropriate arguments)
                  // new <delegate_name>() { public void Invoke(<formal args>) throw exception { [return] arg[0](<args>); } }
                  DelegateRepTemplate delType = $typeCtxt as DelegateRepTemplate;
                  ret = mkDelegateObject((CommonTree)$typeCtxt.Tree, $magicInputPeId.tree, delType, $i.tree.Token);
                  $dotNetType = $typeCtxt;
                  found = true;
               }
            }
            if (!found) {
                // Not a variable, not a property read, not a type, is it part of a type name?
                $dotNetType = new UnknownRepTemplate($i.thetext);
                $thedottedtext =  (implicitThis || String.IsNullOrEmpty($e1.thedottedtext)  ? "" : $e1.thedottedtext + ".") + $i.thetext;
            }
            $rmId = $i.thetext;
            if (ret == null)
               ret = $magicInputPeId.tree;
        }         
    | primary_expression_start                        { $dotNetType = $primary_expression_start.dotNetType; }  
    | literal                                         { $dotNetType = $literal.dotNetType; }  
//	('this'    brackets) => 'this'   brackets   primary_expression_part*
//	| ('base'   brackets) => 'this'   brackets   primary_expression_part*
//	| primary_expression_start   primary_expression_part*
    | ^(n=NEW type argument_list? object_or_collection_initializer?)
        {
         // look for delegate creation
         if ($type.dotNetType is DelegateRepTemplate && $argument_list.argTypes != null && $argument_list.argTypes.Count > 0) {

            // argument_list should consist of just a single expression, either a method group or a value of a delegate type.
            // If its a delegate type, then that is the result of this expression otherwise we create a delegte object.
            if ($argument_list.argTypes[0] is DelegateRepTemplate) {
               ret = dupTree((CommonTree)adaptor.GetChild($argument_list.tree, 0));
               $dotNetType = $argument_list.argTypes[0];
            }
            else {
               // Since 'type' is a delegate then we assume that argument_list[0] will be a method group name.
               // use an anonymous inner class to generate a delegate object (object wih an Invoke with appropriate arguments)
               // new <delegate_name>() { public void Invoke(<formal args>) throw exception { [return] arg[0](<args>); } }
               DelegateRepTemplate delType = $type.dotNetType as DelegateRepTemplate;
               ret = mkDelegateObject($type.tree, (CommonTree)adaptor.GetChild($argument_list.tree, 0), delType, $n.token);
               $dotNetType = $type.dotNetType;
            }
         }
         else {
            // assume object constructor
            ClassRepTemplate conType = $type.dotNetType as ClassRepTemplate;
            $dotNetType = $type.dotNetType;
            if (conType == null) {
               conType = new UnknownRepTemplate("CONSTRUCTOR");
            }
            ResolveResult conResult = conType.Resolve($argument_list.argTypes, AppEnv);
            if (conResult != null) {
               if (!String.IsNullOrEmpty(conResult.Result.Warning)) Warning($n.line, conResult.Result.Warning);
                ConstructorRepTemplate conRep = conResult.Result as ConstructorRepTemplate;
                Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                for (int idx = 0; idx < conRep.Params.Count; idx++) {
                    myMap[conRep.Params[idx].Name] = wrapArgument($argument_list.argTrees[idx], $n.token);
                }
                if ($type.argTrees != null && $type.argTrees.Count == $type.dotNetType.TypeParams.Length) {
                   int idx = 0;
                   foreach (CommonTree ty in $type.argTrees)
                   {
                      myMap[$type.dotNetType.TypeParams[idx]] = wrapType(ty, $n.token);
                      idx++;
                   }
                }
                ret = mkJavaWrapper(conResult.Result.Java, myMap, $n.token);
                AddToImports(conResult.Result.Imports);
                $dotNetType = conResult.ResultType; 
            }
            else if ($argument_list.argTypes != null && $argument_list.argTypes.Count > 0) { // assume we have a zero-arg constructor, so don't print warning 
               WarningFailedResolve($n.token.Line, "Could not resolve constructor against " + conType.TypeName);
            }
         }
        }
    | ^(NEW_ANON_OBJECT anonymous_object_creation_expression)							// new {int X, string Y} 
	| sizeof_expression						// sizeof (struct)
	| checked_expression            		// checked (...
	| unchecked_expression          		// unchecked {...}
	| default_value_expression      		// default
	| ^(d='delegate'   formal_parameter_list?   block)
      {
         if ($typeCtxt != null && $typeCtxt is DelegateRepTemplate) {
            // Since 'type' is a delegate then we assume that argument_list[0] will be a method group name.
            // use an anonymous inner class to generate a delegate object (object wih an Invoke with appropriate arguments)
            // new <delegate_name>() { public void Invoke(<formal args>) throw exception { [return] arg[0](<args>); } }
            DelegateRepTemplate delType = $typeCtxt as DelegateRepTemplate;
            ret = mkDelegateObject((CommonTree)$typeCtxt.Tree, $formal_parameter_list.tree, $block.tree, delType, $d.token);
            $dotNetType = $typeCtxt;
         }
      }
	| typeof_expression          { $dotNetType = $typeof_expression.dotNetType; $typeofType = $typeof_expression.typeofType; }   // typeof(Foo).Name
	;

primary_expression_start returns [TypeRepTemplate dotNetType]:
	 ^('::' identifier identifier)
	;

// primary_expression_part:
// 	 access_identifier
// 	| brackets_or_arguments 
// 	| '++'
// 	| '--' ;
access_identifier:
	access_operator   type_or_generic[""] ;
access_operator:
	'.'  |  '->' ;
brackets_or_arguments:
	brackets | arguments ;
brackets:
	'['   expression_list?   ']' ;	
paren_expression[TypeRepTemplate typeCtxt]:	
	'('   expression[$typeCtxt]   ')' ;
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
argument_value returns [TypeRepTemplate dotNetType, TypeRepTemplate typeofType]
@init {
   string refVar = null;
}:
	expression[ObjectType] { $dotNetType = $expression.dotNetType; $typeofType = $expression.typeofType; } 
	| ref_variable_reference { $dotNetType = $ref_variable_reference.dotNetType; $typeofType = $ref_variable_reference.typeofType; } 
	| o='out'   variable_reference { refVar = "refVar___" + dummyRefVarCtr++; } 
      magicCreateOutVar[$o.token, refVar, ($variable_reference.dotNetType != null ? (CommonTree)$variable_reference.dotNetType.Tree : null)] 
      magicUpdateFromRefVar[$o.token, refVar, $variable_reference.tree, $variable_reference.dotNetType != null && $variable_reference.dotNetType.IsWrapped]
      { $dotNetType = $variable_reference.dotNetType;
        $typeofType = $variable_reference.typeofType; 
        AddToImports("CS2JNet.JavaSupport.language.RefSupport");
        adaptor.AddChild($statement::preStatements, $magicCreateOutVar.tree);
        adaptor.AddChild($statement::postStatements, $magicUpdateFromRefVar.tree);
      } 
       -> IDENTIFIER[$o.token, refVar]
    ;
ref_variable_reference returns [TypeRepTemplate dotNetType, TypeRepTemplate typeofType]
@init {
   string refVar = null;
}:
	r='ref' 
		(('('   type   ')') =>   '('   type   ')'   (ref_variable_reference | variable_reference) { $dotNetType = $type.dotNetType; }   // SomeFunc(ref (int) ref foo)
																									// SomeFunc(ref (int) foo)
		| v1=variable_reference 	// SomeFunc(ref foo)
            { refVar = "refVar___" + dummyRefVarCtr++; } 
            magicCreateRefVar[$r.token, refVar, ($v1.dotNetType != null ? (CommonTree)$v1.dotNetType.Tree : null), $v1.tree] 
            magicUpdateFromRefVar[$r.token, refVar, $v1.tree, $v1.dotNetType != null && $v1.dotNetType.IsWrapped]
            { 
              $dotNetType = $v1.dotNetType; $typeofType = $v1.typeofType;
              AddToImports("CS2JNet.JavaSupport.language.RefSupport");
              adaptor.AddChild($statement::preStatements, $magicCreateRefVar.tree);
              adaptor.AddChild($statement::postStatements, $magicUpdateFromRefVar.tree);
            } 
       -> IDENTIFIER[$r.token, refVar])
     ;
// lvalue
variable_reference returns [TypeRepTemplate dotNetType, TypeRepTemplate typeofType]:
	expression[ObjectType] { $dotNetType = $expression.dotNetType; $typeofType = $expression.typeofType; };
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
	qid   ('='   expression[ObjectType])? ;
primary_or_array_creation_expression[TypeRepTemplate typeCtxt] returns [TypeRepTemplate dotNetType, string rmId, TypeRepTemplate typeofType, string thedottedtext]:
	(array_creation_expression) => array_creation_expression { $dotNetType = $array_creation_expression.dotNetType; $thedottedtext = null; }
	| primary_expression[$typeCtxt] { $dotNetType = $primary_expression.dotNetType; $rmId = $primary_expression.rmId; $typeofType = $primary_expression.typeofType; $thedottedtext = $primary_expression.thedottedtext; }
	;
// new Type[2] { }
array_creation_expression returns [TypeRepTemplate dotNetType]:
	^(NEW_ARRAY   
		(type   ('['   expression_list   ']' rank_specifiers[$type.dotNetType]?   array_initializer?	// new int[4]
				| array_initializer	{ $dotNetType = $type.dotNetType; } 	
				)
		| rank_specifier[null] array_initializer	// var a = new[] { 1, 10, 100, 1000 }; // int[]
		)
     ) ;
array_initializer:
	'{'   variable_initializer_list?   ','?   '}' ;
variable_initializer_list:
	variable_initializer[ObjectType] (',' variable_initializer[ObjectType])* ;
variable_initializer[TypeRepTemplate typeCtxt]:
	expression[$typeCtxt]	| array_initializer ;
sizeof_expression:
	^('sizeof'  unmanaged_type );
checked_expression: 
	^('checked' expression[ObjectType] ) ;
unchecked_expression: 
	^('unchecked' expression[ObjectType] ) ;
default_value_expression: 
	^('default' type   ) ;

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
	non_assignment_expression[ObjectType] 
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
	member_initializer  (',' member_initializer)* ;
member_initializer: 
	identifier   '='   initializer_value ;
initializer_value: 
	expression[ObjectType] 
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

// i.e not a predefined type.
type_name returns [TypeRepTemplate dotNetType, List<CommonTree> argTrees, bool hasTyArgs]
@init {
   $hasTyArgs = false;
   Dictionary<string,CommonTree> tyMap = new Dictionary<string,CommonTree>();
}
@after {
   AddToImports($dotNetType.Imports);
}
:
	 tg=type_or_generic[""] { $dotNetType = $tg.dotNetType; $argTrees = $tg.argTrees; $hasTyArgs = $tg.hasTyArgs; }
    | ^('::' ct=type_name ctg=type_or_generic[$ct.dotNetType == null ? "::" : $ct.dotNetType.TypeName+"::"]) 
      { 
         // give up, we don't support these, pretty printer will wrap in a comment
         $dotNetType = $ctg.dotNetType;
         $hasTyArgs = $ctg.hasTyArgs;
         $argTrees = $ctg.argTrees;
      } 
    | ^(d='.'   dt=type_name dtg=type_or_generic[$dt.dotNetType == null ? "." : $dt.dotNetType.TypeName+"."]) 
      { 
         WarningAssert(!$dt.hasTyArgs, $d.token.Line, "Didn't expect type arguments in prefix of type name"); 

         $dotNetType = $dtg.dotNetType;
         if (!$dotNetType.IsUnknownType) {
            if ($dotNetType.TypeParams.Length == $dtg.argTrees.Count) {
               int i = 0;
               foreach (CommonTree ty in $dtg.argTrees) {
                  tyMap[$dotNetType.TypeParams[i]] = wrapType(ty, $dt.tree.Token);
                  i++;
               }
               $hasTyArgs = true; 
               $argTrees = $dtg.argTrees;
            }
         }
      } 
      -> {!$dotNetType.IsUnknownType}? { mkJavaWrapper($dotNetType.Java, tyMap, $dt.tree.Token) } 
      -> ^($d $dt $dtg)
     ;

type_or_generic[String prefix] returns [TypeRepTemplate dotNetType, List<CommonTree> argTrees, bool hasTyArgs]
@init {
   $hasTyArgs = false;
   $argTrees = new List<CommonTree>();
   Dictionary<string,CommonTree> tyMap = new Dictionary<string,CommonTree>();
}
@after {
   AddToImports($dotNetType.Imports);
}
:
//	(identifier   generic_argument_list) => t=identifier  ga=generic_argument_list 
	t=identifier  (ga=generic_argument_list {$hasTyArgs = true;})? 
      { 
         $dotNetType = findType(prefix+$t.thetext, $ga.argTypes); 
         if (!$dotNetType.IsUnknownType) {
            if (!$MkNonGeneric::scrubGenericArgs && $hasTyArgs && $dotNetType.TypeParams.Length == $ga.argTrees.Count) {
               int i = 0;
               foreach (CommonTree ty in $ga.argTrees) {
                  tyMap[$dotNetType.TypeParams[i]] = wrapType(ty, $t.tree.Token);
                  i++;
               }
               $argTrees = $ga.argTrees;
            }
         }
      } 
      -> {!this.in_member_name && !$dotNetType.IsUnknownType}? { mkJavaWrapper($dotNetType.Java, tyMap, $t.tree.Token) } 
      -> $t $ga?
   ;
// 	| ity=identifier_type[prefix] 
//       { $dotNetType = $ity.dotNetType); 
//       } 
//       -> {!$dotNetType.IsUnknownType}? { mkJavaWrapper($dotNetType.Java, null, $ity.tree.Token) } 
//       -> $ity
//       ;
// 
// identifier_type[string prefix] returns [string thetext]
// @init {
//     TypeRepTemplate tyRep = null;
// }
// @after{
//     $thetext = $t.thetext;
//     AddToImports($dotNetType.Imports);
// }:
//     t=identifier { tyRep = findType(prefix+$t.thetext); } 
//         -> { mkJavaWrapper(tyRep.Java, null, $t.tree.Token) } 
//    ;
// 
qid:		// qualified_identifier v2
    ^(access_operator qid type_or_generic[""]) 
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

generic_argument_list returns [List<TypeRepTemplate> argTypes, List<CommonTree> argTrees]: 
	'<'   type_arguments   '>' { $argTypes = $type_arguments.tyTypes; $argTrees = $type_arguments.argTrees; };
type_arguments  returns [List<TypeRepTemplate> tyTypes, List<CommonTree> argTrees]
scope PrimitiveRep;
@init {
    $PrimitiveRep::primitiveTypeAsObject = true;
    $tyTypes = new List<TypeRepTemplate>();
    $argTrees = new List<CommonTree>();
}: 
	t1=type { $tyTypes.Add($t1.dotNetType); $argTrees.Add(dupTree($t1.tree)); } (',' tn=type { $tyTypes.Add($tn.dotNetType); $argTrees.Add(dupTree($tn.tree)); })* ;

// keving: TODO: Look for type vars
type returns [TypeRepTemplate dotNetType, List<CommonTree> argTrees]
@ init {
   bool hasRank = false;
   bool isPredefined = false;
   CommonTree pTree = null;
   string boxedName = null;
}
@after {
   if ($dotNetType.Tree == null) {
      $dotNetType.Tree = $type.tree;
   }
}
:
    ^(TYPE (p=predefined_type { isPredefined = true; $dotNetType = $predefined_type.dotNetType; pTree = $p.tree; boxedName = $predefined_type.dotNetType.BoxedName; } 
           | type_name { $dotNetType = $type_name.dotNetType; $argTrees = $type_name.argTrees; } 
           | 'void' { $dotNetType = AppEnv["System.Void"]; } )  
        (rank_specifiers[$dotNetType] { isPredefined = false; $dotNetType = $rank_specifiers.dotNetType; $argTrees = null; hasRank = true; })? '*'* '?'?) 
        magicBoxedType[isPredefined && pTree != null && !String.IsNullOrEmpty(boxedName), (pTree != null ? pTree.Token : null), boxedName]
       { $dotNetType.Tree = ($magicBoxedType.tree != null ? dupTree($magicBoxedType.tree) : null); }
    -> { $PrimitiveRep::primitiveTypeAsObject && $p.tree != null && !hasRank && !String.IsNullOrEmpty($dotNetType.BoxedName) }? ^(TYPE[$p.tree.Token, "TYPE"] IDENTIFIER[$p.tree.Token,$dotNetType.BoxedName] '*'* '?'?)
    -> ^(TYPE predefined_type? type_name? 'void'? rank_specifiers? '*'* '?'?)
;

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
	statement[/* isStatementListCtxt */ true]+ ;
	
///////////////////////////////////////////////////////
//	Expression Section
///////////////////////////////////////////////////////	
expression[TypeRepTemplate typeCtxt] returns [TypeRepTemplate dotNetType, string rmId, TypeRepTemplate typeofType, string thedottedtext]
: 
	(unary_expression[ObjectType]   assignment_operator) => assignment	    { $dotNetType = VoidType; $thedottedtext = null;}
	| non_assignment_expression[$typeCtxt]                                 { $dotNetType = $non_assignment_expression.dotNetType; $rmId = $non_assignment_expression.rmId; $typeofType = $non_assignment_expression.typeofType; $thedottedtext = $non_assignment_expression.thedottedtext; }
	;
expression_list returns [List<TypeRepTemplate> expTypes, List<CommonTree> expTrees, List<TypeRepTemplate> expTreeTypeofTypes]
@init {
    $expTypes = new List<TypeRepTemplate>();
    $expTrees = new List<CommonTree>();
    $expTreeTypeofTypes = new List<TypeRepTemplate>();
}:
	e1=expression[ObjectType] { $expTypes.Add($e1.dotNetType); $expTrees.Add(dupTree($e1.tree)); $expTreeTypeofTypes.Add($e1.typeofType); }
      (','   en=expression[ObjectType] { $expTypes.Add($en.dotNetType); $expTrees.Add(dupTree($en.tree)); $expTreeTypeofTypes.Add($en.typeofType); })* ;

assignment
@init {
    CommonTree ret = null;
    bool isThis = false;
    bool isLocalVar = false;
    TypeRepTemplate expType = null;
    TypeRepTemplate lhsType = ObjectType;

    ResolveResult fieldResult = null;
    ResolveResult indexerResult = null;

    CommonTree lhsTree = null;
}
@after {
    if (ret != null)
        $assignment.tree = ret;
}:
    ((^('.' expression[ObjectType] identifier generic_argument_list?) | identifier) assignment_operator)  => 
        (^(d0='.' se=expression[ObjectType] i=identifier generic_argument_list?)  {lhsTree = dupTree($d0.tree); }
          | i=identifier { isThis = true; lhsTree = dupTree($i.tree); })  
            {
                TypeRepTemplate varType = SymTabLookup($i.thetext);
                if (isThis && varType != null) {
                   isLocalVar = true;
                   lhsType = varType;
                }   
                else {
                   expType = (isThis ? SymTabLookup("this") : $se.dotNetType);
                   if (expType == null) {
                      expType = new UnknownRepTemplate("FIELD.BASE");
                   }
                   if (expType.IsUnknownType) {
                      WarningFailedResolve($i.tree.Token.Line, "Could not find type of expression for field /property access");
                   }
                   fieldResult = expType.Resolve($i.thetext, true, AppEnv);
                   if (fieldResult != null) {
                      lhsType = fieldResult.ResultType ?? lhsType;
                   }
                }
            }
         a=assignment_operator rhs=expression[lhsType] 
        {
            CommonTree assignmentOp = $a.tree;
            CommonTree rhsTree = $rhs.tree;
            TypeRepTemplate rhsType = $rhs.dotNetType ?? ObjectType;
            // Is lhs a delegate and assignment one of += -=?
            if (lhsType is DelegateRepTemplate && (assignmentOp.Token.Type == PLUS_ASSIGN || assignmentOp.Token.Type == MINUS_ASSIGN)) {
               // rewrite to lhs = <op>(lhs,rhs)
               // First calculate new rhs
               CommonTree lhsGetter = lhsTree;
               // Do we have a getter for lhs
               if (isLocalVar && lhsType.IsWrapped) {
                  Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                  myMap["this"] = wrapExpression($i.tree, $i.tree.Token);
                  lhsGetter = mkJavaWrapper("${this}.getValue()", myMap, $i.tree.Token);
               }
               else if (expType != null) {
                  // Is lhs a property?
                  ResolveResult readFieldResult = expType.Resolve($i.thetext, false, AppEnv);
                  if (readFieldResult.Result is PropRepTemplate) {
                     if (!String.IsNullOrEmpty(readFieldResult.Result.Warning)) Warning($i.tree.Token.Line, readFieldResult.Result.Warning);
                     PropRepTemplate readPropRep = readFieldResult.Result as PropRepTemplate;
                  
                     if (!String.IsNullOrEmpty(readPropRep.JavaGet)) {
                        // need to translate to setProp(getProp <op> rhs)
                        Dictionary<string,CommonTree> rhsMap = new Dictionary<string,CommonTree>();
                        if (!isThis)
                           rhsMap["this"] = wrapExpression($se.tree, $i.tree.Token);
                        lhsGetter = mkJavaWrapper(readPropRep.JavaGet, rhsMap, assignmentOp.Token);
                        lhsType = readFieldResult.ResultType;
                     }
                  }
               }
               // OK, lhsGetter is good for use.
               List<TypeRepTemplate> args = new List<TypeRepTemplate>();
               args.Add(lhsType);
               args.Add(rhsType == null ? lhsType : rhsType);
               ResolveResult calleeResult = lhsType.Resolve(assignmentOp.Token.Type == PLUS_ASSIGN ? "Combine" : "Remove", args, AppEnv);
               if (calleeResult != null) {
                  if (!String.IsNullOrEmpty(calleeResult.Result.Warning)) Warning(assignmentOp.Token.Line, calleeResult.Result.Warning);
                  
                  Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                  MethodRepTemplate calleeMethod = calleeResult.Result as MethodRepTemplate;
                  myMap[calleeMethod.Params[0].Name] = wrapArgument(lhsGetter, assignmentOp.token);
                  myMap[calleeMethod.Params[1].Name] = wrapArgument(rhsTree, assignmentOp.token);
                  rhsTree = mkJavaWrapper(calleeMethod.Java, myMap, assignmentOp.token);
                  AddToImports(calleeMethod.Imports);
                  rhsType = calleeResult.ResultType; 
                  assignmentOp = (CommonTree)adaptor.Create(ASSIGN, assignmentOp.Token, "=");
                  
                  // set up a default ret
                  ret = (CommonTree)adaptor.Nil;
                  adaptor.AddChild(ret, dupTree(lhsTree));
                  adaptor.AddChild(ret, dupTree(assignmentOp));
                  adaptor.AddChild(ret, dupTree(rhsTree));
               }
               else {
                  WarningFailedResolve(assignmentOp.Token.Line, "Could not resolve method application of " + (assignmentOp.Token.Type == PLUS_ASSIGN ? "Combine" : "Remove") + " against " + lhsType.TypeName);
               }
            } 
            if (isLocalVar) {
               // Is this a wrapped parameter?
               if (lhsType.IsWrapped) {
                  CommonTree newRhsExp = rhsTree;
                  if (assignmentOp.Token.Type != ASSIGN) {
                     Dictionary<string,CommonTree> rhsMap = new Dictionary<string,CommonTree>();
                     rhsMap["this"] = wrapExpression($i.tree, $i.tree.Token);
                     CommonTree rhsPropTree = mkJavaWrapper("${this}.getValue()", rhsMap, assignmentOp.Token);
                     newRhsExp = mkOpExp(mkOpExp(assignmentOp), rhsPropTree, rhsTree);
                  }
                  Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                  myMap["this"] = wrapExpression($i.tree, $i.tree.Token);
                  myMap["value"] = wrapExpression(newRhsExp, rhsTree.Token);
                  ret = mkJavaWrapper("${this}.setValue(${value})", myMap, $i.tree.Token);
                }
               // a simple variable assignment
            }
            else {
               if (fieldResult != null) {
                  if (!String.IsNullOrEmpty(fieldResult.Result.Warning)) Warning($i.tree.Token.Line, fieldResult.Result.Warning);
                  if (fieldResult.Result is PropRepTemplate) {
                     PropRepTemplate propRep = fieldResult.Result as PropRepTemplate;
                     if (!String.IsNullOrEmpty(propRep.JavaSet)) {
                        CommonTree newRhsExp = rhsTree;
                        // if assignment operator is a short cut operator then only translate if we also have JavaGet  
                        bool goodTx = true;
                        if (assignmentOp.Token.Type != ASSIGN) {
                           // We have to resolve property reads and writes separately, because they may come from 
                           // different parent classes
                           ResolveResult readFieldResult = expType.Resolve($i.thetext, false, AppEnv);
                           if (readFieldResult.Result is PropRepTemplate) {
                              if (!String.IsNullOrEmpty(readFieldResult.Result.Warning)) Warning($i.tree.Token.Line, readFieldResult.Result.Warning);
                              PropRepTemplate readPropRep = readFieldResult.Result as PropRepTemplate;

                              if (!String.IsNullOrEmpty(readPropRep.JavaGet)) {
                                 // we have prop <op>= rhs
                                 // need to translate to setProp(getProp <op> rhs)
                                 Dictionary<string,CommonTree> rhsMap = new Dictionary<string,CommonTree>();
                                 if (!isThis)
                                    rhsMap["this"] = wrapExpression($se.tree, $i.tree.Token);
                                 CommonTree rhsPropTree = mkJavaWrapper(readPropRep.JavaGet, rhsMap, assignmentOp.Token);
                                 newRhsExp = mkOpExp(mkOpExp(assignmentOp), rhsPropTree, rhsTree);
                              }
                              else {
                                 goodTx = false;
                              }
                           }
                        }
                        Dictionary<string,CommonTree> valMap = new Dictionary<string,CommonTree>();
                        if (!isThis)
                           valMap["this"] = wrapExpression($se.tree, $i.tree.Token);
                        valMap["value"] = wrapExpression(newRhsExp, $i.tree.Token);
                        if (goodTx) {
                           ret = mkJavaWrapper(propRep.JavaSet, valMap, assignmentOp.Token);
                           AddToImports(propRep.Imports);
                        }
                     }
                  }
               }
               else {
                  WarningFailedResolve($i.tree.Token.Line, "Could not resolve field or property expression against " + expType.ToString());
               }
            }
        }
    | (^(INDEX expression[ObjectType] expression_list?) assignment_operator)  => 
        ^(INDEX ie=expression[ObjectType] expression_list?)
          {
            expType = $ie.dotNetType ?? (new UnknownRepTemplate("INDEXER.BASE"));
            if (expType.IsUnknownType) {
               WarningFailedResolve($ie.tree.Token.Line, "Could not find type of expression for Indexer");
            }
            indexerResult = expType.ResolveIndexer($expression_list.expTypes ?? new List<TypeRepTemplate>(), AppEnv);
            if (indexerResult != null) {
               lhsType = indexerResult.ResultType ?? lhsType;
            }
          }   
        ia=assignment_operator irhs=expression[lhsType] 
        {
            if (indexerResult != null) {
               if (!String.IsNullOrEmpty(indexerResult.Result.Warning)) Warning($ia.tree.Token.Line, indexerResult.Result.Warning);
               IndexerRepTemplate indexerRep = indexerResult.Result as IndexerRepTemplate;
               if (!String.IsNullOrEmpty(indexerRep.JavaSet)) {
                  CommonTree newRhsExp = $irhs.tree;
                  // if assignment operator is a short cut operator then only translate if we also have JavaGet  
                  bool goodTx = true;
                  if ($ia.tree.Token.Type != ASSIGN) {
                     if (!String.IsNullOrEmpty(indexerRep.JavaGet)) {
                        // we have indexable[args] <op>= rhs
                        // need to translate to set___idx(args, get___idx(args) <op> rhs)
                        Dictionary<string,CommonTree> rhsMap = new Dictionary<string,CommonTree>();
                        rhsMap["this"] = wrapExpression($ie.tree, $ie.tree.Token);
                        for (int idx = 0; idx < indexerRep.Params.Count; idx++) {
                           rhsMap[indexerRep.Params[idx].Name] = wrapArgument($expression_list.expTrees[idx], $ie.tree.Token);
                           if (indexerRep.Params[idx].Name.StartsWith("TYPEOF") && $expression_list.expTreeTypeofTypes[idx] != null) {
                              // if this argument is a typeof expression then add a TYPEOF_TYPEOF-> typeof's type mapping
                              rhsMap[indexerRep.Params[idx].Name + "_TYPE"] = wrapTypeOfType($expression_list.expTreeTypeofTypes[idx], $ie.tree.Token);
                           }
                        }
                        
                        CommonTree rhsIdxTree = mkJavaWrapper(indexerRep.JavaGet, rhsMap, $ia.tree.Token);
                        newRhsExp = mkOpExp(mkOpExp($ia.tree), rhsIdxTree, $irhs.tree);
                     }
                     else {
                        goodTx = false;
                     }
                  }

                  Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                  myMap["this"] = wrapExpression($ie.tree, $ie.tree.Token);
                  myMap["value"] = wrapExpression(newRhsExp, newRhsExp.Token);
                  for (int idx = 0; idx < indexerRep.Params.Count; idx++) {
                     myMap[indexerRep.Params[idx].Name] = wrapArgument($expression_list.expTrees[idx], $ie.tree.Token);
                     if (indexerRep.Params[idx].Name.StartsWith("TYPEOF") && $expression_list.expTreeTypeofTypes[idx] != null) {
                        // if this argument is a typeof expression then add a TYPEOF_TYPEOF-> typeof's type mapping
                        myMap[indexerRep.Params[idx].Name + "_TYPE"] = wrapTypeOfType($expression_list.expTreeTypeofTypes[idx], $ie.tree.Token);
                     }
                  }
                  if (goodTx) {
                     ret = mkJavaWrapper(indexerRep.JavaSet, myMap, $ie.tree.Token);
                     AddToImports(indexerRep.Imports);
                  }
               }   
            }
            else {
               WarningFailedResolve($ie.tree.Token.Line, "Could not resolve index expression against " + expType.ToString());
            }
      }
    | unary_expression[ObjectType]   assignment_operator expression[ObjectType] ;


unary_expression[TypeRepTemplate typeCtxt] returns [TypeRepTemplate dotNetType, string rmId, TypeRepTemplate typeofType, string thedottedtext]
@init {
   $thedottedtext = null;
}: 
	//('(' arguments ')' ('[' | '.' | '(')) => primary_or_array_creation_expression	

    cast_expression                             { $dotNetType = $cast_expression.dotNetType; }
	| primary_or_array_creation_expression[$typeCtxt]      { $dotNetType = $primary_or_array_creation_expression.dotNetType; $rmId = $primary_or_array_creation_expression.rmId; $typeofType = $primary_or_array_creation_expression.typeofType; $thedottedtext = $primary_or_array_creation_expression.thedottedtext; }
	| ^(MONOPLUS u1=unary_expression[ObjectType])           { $dotNetType = $u1.dotNetType; }
	| ^(MONOMINUS u2=unary_expression[ObjectType])          { $dotNetType = $u2.dotNetType; }
	| ^(MONONOT u3=unary_expression[ObjectType])            { $dotNetType = $u3.dotNetType; }
	| ^(MONOTWIDDLE u4=unary_expression[ObjectType])        { $dotNetType = $u4.dotNetType; }
	| ^(PREINC u5=unary_expression[ObjectType])             { $dotNetType = $u5.dotNetType; }
	| ^(PREDEC u6=unary_expression[ObjectType])             { $dotNetType = $u6.dotNetType; }
	| ^(MONOSTAR unary_expression[ObjectType])              { $dotNetType = ObjectType; }
	| ^(ADDRESSOF unary_expression[ObjectType])             { $dotNetType = ObjectType; }
	| ^(PARENS expression[$typeCtxt])                      { $dotNetType = $expression.dotNetType; $rmId = $expression.rmId; $typeofType = $expression.typeofType; }
	;

cast_expression  returns [TypeRepTemplate dotNetType]
@init {
    CommonTree ret = null;
}
@after {
    if (ret != null)
        $cast_expression.tree = ret;
}:
    ^(c=CAST_EXPR type expression[$type.dotNetType ?? ObjectType]) 
       { 
            $dotNetType = $type.dotNetType;
            if ($type.dotNetType != null && $expression.dotNetType != null) {
                // see if expression's type has a cast to type
                ResolveResult kaster = $expression.dotNetType.ResolveCastTo($type.dotNetType, AppEnv);
                if (kaster == null) {
                    // see if type has a cast from expression's type
                    kaster = $type.dotNetType.ResolveCastFrom($expression.dotNetType, AppEnv);
                }
                if (kaster != null) {
                    if (!String.IsNullOrEmpty(kaster.Result.Warning)) Warning($c.line, kaster.Result.Warning);
                    Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                    myMap["expr"] = wrapExpression($expression.tree, $c.token);
                    myMap["TYPEOF_totype"] = wrapTypeOfType($type.dotNetType, $c.token);
                    myMap["TYPEOF_expr"] = wrapTypeOfType($expression.dotNetType, $c.token);
                    ret = mkJavaWrapper(kaster.Result.Java, myMap, $c.token);
                    AddToImports(kaster.Result.Imports);
                }
            }
       }
         ->  ^($c  { ($expression.dotNetType != null && $expression.dotNetType.TypeName == "System.Object" ? mkBoxedType($type.tree, $type.tree.Token) : $type.tree) }  expression)         
//         ->  ^($c  { ($type.dotNetType.IsUnboxedType && !$unary_expression.dotNetType.IsUnboxedType ? mkBoxedType($type.tree, $type.tree.Token) : $type.tree) }  unary_expression)         
;         
assignment_operator:
	'=' | shortcut_assignment_operator ;
shortcut_assignment_operator: '+=' | '-=' | '*=' | '/=' | '%=' | '&=' | '|=' | '^=' | '<<=' | RIGHT_SHIFT_ASSIGN ;
//pre_increment_expression: 
//	'++'   unary_expression ;
//pre_decrement_expression: 
//	'--'   unary_expression ;
//pointer_indirection_expression:
//	'*'   unary_expression ;
//addressof_expression:
//	'&'   unary_expression ;

non_assignment_expression[TypeRepTemplate typeCtxt] returns [TypeRepTemplate dotNetType, string rmId, TypeRepTemplate typeofType, string thedottedtext]
scope MkNonGeneric, PrimitiveRep;
@init {
    $MkNonGeneric::scrubGenericArgs = false;
    $PrimitiveRep::primitiveTypeAsObject = false;
    bool nullArg = false;
    bool stringArgs = false;
    bool dateArgs = false;
    $thedottedtext = null;
    CommonTree ret = null;
}
@after{
   if (ret != null)
      $non_assignment_expression.tree = ret;
}:
	//'non ASSIGNment'
	(anonymous_function_signature[null]?   '=>')	=> lambda_expression[$typeCtxt] { $dotNetType = $lambda_expression.dotNetType; } 
	| (query_expression) => query_expression 
	|     ^(COND_EXPR non_assignment_expression[ObjectType] e1=expression[ObjectType] e2=expression[ObjectType])  {$dotNetType = $e1.dotNetType; }
        | ^('??' n1=non_assignment_expression[ObjectType] non_assignment_expression[ObjectType])      {$dotNetType = $n1.dotNetType; }
        | ^('||' n2=non_assignment_expression[ObjectType] non_assignment_expression[ObjectType])      {$dotNetType = $n2.dotNetType; }
        | ^('&&' n3=non_assignment_expression[ObjectType] non_assignment_expression[ObjectType])      {$dotNetType = $n3.dotNetType; }
        | ^('|' n4=non_assignment_expression[ObjectType] non_assignment_expression[ObjectType])       {$dotNetType = $n4.dotNetType; }
        | ^('^' n5=non_assignment_expression[ObjectType] non_assignment_expression[ObjectType])       {$dotNetType = $n5.dotNetType; }
        | ^('&' n6=non_assignment_expression[ObjectType] non_assignment_expression[ObjectType])       {$dotNetType = $n6.dotNetType; }
        | ^(eq='==' ne1=non_assignment_expression[ObjectType] ne2=non_assignment_expression[ObjectType] 
            {
                // if One arg is null then leave original operator
                nullArg = $ne1.dotNetType != null && $ne2.dotNetType != null && ($ne1.dotNetType.IsExplicitNull || $ne2.dotNetType.IsExplicitNull);
                // need to exclude null because that has every type
                stringArgs = !nullArg && (($ne1.dotNetType != null && !$ne1.dotNetType.IsExplicitNull && $ne1.dotNetType.IsA(StringType,AppEnv)) || 
                                            ($ne2.dotNetType != null && !$ne2.dotNetType.IsExplicitNull && $ne2.dotNetType.IsA(StringType,AppEnv)));
                if (stringArgs) {
                    this.AddToImports("CS2JNet.System.StringSupport");
                }
                dateArgs = !nullArg && (($ne1.dotNetType != null && !$ne1.dotNetType.IsExplicitNull && $ne1.dotNetType.IsA(DateType,AppEnv)) || 
                                           ($ne2.dotNetType != null && !$ne2.dotNetType.IsExplicitNull && $ne2.dotNetType.IsA(DateType,AppEnv)));
                if (dateArgs) {
                    this.AddToImports("CS2JNet.System.DateTimeSupport");
                }
                $dotNetType = BoolType; 
            }
            opse=magicSupportOp[stringArgs, "StringSupport", "equals", $ne1.tree, $ne2.tree, $eq.token]
            opde=magicSupportOp[dateArgs, "DateTimeSupport", "equals", $ne1.tree, $ne2.tree, $eq.token])
         -> {stringArgs}? 
               $opse
         -> {dateArgs}? 
               $opde
         ->^($eq $ne1 $ne2)
        | ^(neq='!=' neqo1=non_assignment_expression[ObjectType] neqo2=non_assignment_expression[ObjectType]    
            {
                // if One arg is null then leave original operator
                nullArg = $neqo1.dotNetType != null && $neqo2.dotNetType != null && ($neqo1.dotNetType.IsExplicitNull || $neqo2.dotNetType.IsExplicitNull);
                // need to exclude null because that has every type
                stringArgs = !nullArg && (($neqo1.dotNetType != null && !$neqo1.dotNetType.IsExplicitNull && $neqo1.dotNetType.IsA(StringType,AppEnv)) || 
                                            ($neqo2.dotNetType != null && !$neqo2.dotNetType.IsExplicitNull && $neqo2.dotNetType.IsA(StringType,AppEnv)));
                if (stringArgs) {
                    this.AddToImports("CS2JNet.System.StringSupport");
                }
                dateArgs = !nullArg && (($neqo1.dotNetType != null && !$neqo1.dotNetType.IsExplicitNull && $neqo1.dotNetType.IsA(DateType,AppEnv)) || 
                                           ($neqo2.dotNetType != null && !$neqo2.dotNetType.IsExplicitNull && $neqo2.dotNetType.IsA(DateType,AppEnv)));
                if (dateArgs) {
                    this.AddToImports("CS2JNet.System.DateTimeSupport");
                }
                $dotNetType = BoolType; 
            }
            opse1=magicSupportOp[stringArgs, "StringSupport", "equals", $neqo1.tree, $neqo2.tree, $neq.token]
            opsne=magicNegate[stringArgs, $opse1.tree, $neq.token]
            opde1=magicSupportOp[dateArgs, "DateTimeSupport", "equals", $neqo1.tree, $neqo2.tree, $neq.token]
            opdne=magicNegate[dateArgs, $opde1.tree, $neq.token])
         -> {stringArgs}? 
               $opsne
         -> {dateArgs}? 
               $opdne
         ->^($neq $neqo1 $neqo2)
        | ^(gt='>' gt1=non_assignment_expression[ObjectType] gt2=non_assignment_expression[ObjectType]
            {
                // if One arg is null then leave original operator
                nullArg = $gt1.dotNetType != null && $gt2.dotNetType != null && ($gt1.dotNetType.IsExplicitNull || $gt2.dotNetType.IsExplicitNull);
                // need to exclude null because that has every type
                dateArgs = !nullArg && (($gt1.dotNetType != null && !$gt1.dotNetType.IsExplicitNull && $gt1.dotNetType.IsA(DateType,AppEnv)) || 
                                           ($gt2.dotNetType != null && !$gt2.dotNetType.IsExplicitNull && $gt2.dotNetType.IsA(DateType,AppEnv)));
                if (dateArgs) {
                    this.AddToImports("CS2JNet.System.DateTimeSupport");
                }
                $dotNetType = BoolType; 
            }
            opgt=magicSupportOp[dateArgs, "DateTimeSupport", "lessthan", $gt2.tree, $gt1.tree, $gt.token])
        -> {dateArgs}? 
               $opgt
         ->^($gt $gt1 $gt2)
        | ^(lt='<' lt1=non_assignment_expression[ObjectType] lt2=non_assignment_expression[ObjectType]
            {
                // if One arg is null then leave original operator
                nullArg = $lt1.dotNetType != null && $lt2.dotNetType != null && ($lt1.dotNetType.IsExplicitNull || $lt2.dotNetType.IsExplicitNull);
                // need to exclude null because that has every type
                dateArgs = !nullArg && (($lt1.dotNetType != null && !$lt1.dotNetType.IsExplicitNull && $lt1.dotNetType.IsA(DateType,AppEnv)) || 
                                           ($lt2.dotNetType != null && !$lt2.dotNetType.IsExplicitNull && $lt2.dotNetType.IsA(DateType,AppEnv)));
                if (dateArgs) {
                    this.AddToImports("CS2JNet.System.DateTimeSupport");
                }
                $dotNetType = BoolType; 
            }
            oplt=magicSupportOp[dateArgs, "DateTimeSupport", "lessthan", $lt1.tree, $lt2.tree, $lt.token])
        -> {dateArgs}? 
               $oplt
         ->^($lt $lt1 $lt2)
        | ^(ge='>=' ge1=non_assignment_expression[ObjectType] ge2=non_assignment_expression[ObjectType]
            {
                // if One arg is null then leave original operator
                nullArg = $ge1.dotNetType != null && $ge2.dotNetType != null && ($ge1.dotNetType.IsExplicitNull || $ge2.dotNetType.IsExplicitNull);
                // need to exclude null because that has every type
                dateArgs = !nullArg && (($ge1.dotNetType != null && !$ge1.dotNetType.IsExplicitNull && $ge1.dotNetType.IsA(DateType,AppEnv)) || 
                                          ($ge2.dotNetType != null && !$ge2.dotNetType.IsExplicitNull && $ge2.dotNetType.IsA(DateType,AppEnv)));
                if (dateArgs) {
                    this.AddToImports("CS2JNet.System.DateTimeSupport");
                }
                $dotNetType = BoolType; 
            }
            opge=magicSupportOp[dateArgs, "DateTimeSupport", "lessthanorequal", $ge2.tree, $ge1.tree, $ge.token])
        -> {dateArgs}? 
               $opge
         ->^($ge $ge1 $ge2)
        | ^(le='<=' le1=non_assignment_expression[ObjectType] le2=non_assignment_expression[ObjectType]
            {
                // if One arg is null then leave original operator
                nullArg = $le1.dotNetType != null && $le2.dotNetType != null && ($le1.dotNetType.IsExplicitNull || $le2.dotNetType.IsExplicitNull);
                // need to exclude null because that has every type
                dateArgs = !nullArg && (($le1.dotNetType != null && !$le1.dotNetType.IsExplicitNull && $le1.dotNetType.IsA(DateType,AppEnv)) || 
                                            ($le2.dotNetType != null && !$le2.dotNetType.IsExplicitNull && $le2.dotNetType.IsA(DateType,AppEnv)));
                if (dateArgs) {
                    this.AddToImports("CS2JNet.System.DateTimeSupport");
                }
                $dotNetType = BoolType; 
            }
            ople=magicSupportOp[dateArgs, "DateTimeSupport", "lessthanorequal", $le1.tree, $le2.tree, $le.token])
        -> {dateArgs}? 
               $ople
         ->^($le $le1 $le2)
        | ^(INSTANCEOF non_assignment_expression[ObjectType] { $MkNonGeneric::scrubGenericArgs = true;  $PrimitiveRep::primitiveTypeAsObject = true; } non_nullable_type)           {$dotNetType = BoolType; }
        | ^('<<' n7=non_assignment_expression[ObjectType] non_assignment_expression[ObjectType])      {$dotNetType = $n7.dotNetType; }
        | ^(RIGHT_SHIFT n8=non_assignment_expression[ObjectType] non_assignment_expression[ObjectType])      {$dotNetType = $n8.dotNetType; }
// TODO: need to munge these numeric types
        | ^(pl='+' n9=non_assignment_expression[ObjectType] n92=non_assignment_expression[ObjectType])       
        {
         // Are we adding two delegates?
         if ($n9.dotNetType != null && $n9.dotNetType is DelegateRepTemplate) {
            List<TypeRepTemplate> args = new List<TypeRepTemplate>();
            args.Add($n9.dotNetType);
            args.Add($n92.dotNetType == null ? $n9.dotNetType : $n92.dotNetType);
            ResolveResult calleeResult = $n9.dotNetType.Resolve("Combine", args, AppEnv);
            if (calleeResult != null) {
               if (!String.IsNullOrEmpty(calleeResult.Result.Warning)) Warning($pl.line, calleeResult.Result.Warning);
                  
               Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
               MethodRepTemplate calleeMethod = calleeResult.Result as MethodRepTemplate;
               myMap[calleeMethod.Params[0].Name] = wrapArgument($n9.tree, $pl.token);
               myMap[calleeMethod.Params[1].Name] = wrapArgument($n92.tree, $pl.token);
               ret = mkJavaWrapper(calleeMethod.Java, myMap, $pl.token);
               AddToImports(calleeMethod.Imports);
               $dotNetType = calleeResult.ResultType; 
            }
            else {
               WarningFailedResolve($pl.line, "Could not resolve method application of Combine against " + $n9.dotNetType.TypeName);
            }
         }
         $dotNetType = $n9.dotNetType; 
        }
        | ^(ne='-' n10=non_assignment_expression[ObjectType] n102=non_assignment_expression[ObjectType])      {$dotNetType = $n10.dotNetType; }
        {
         // Are we adding two delegates?
         if ($n10.dotNetType != null && $n10.dotNetType is DelegateRepTemplate) {
            List<TypeRepTemplate> args = new List<TypeRepTemplate>();
            args.Add($n10.dotNetType);
            args.Add($n102.dotNetType == null ? $n10.dotNetType : $n102.dotNetType);
            ResolveResult calleeResult = $n10.dotNetType.Resolve("Remove", args, AppEnv);
            if (calleeResult != null) {
               if (!String.IsNullOrEmpty(calleeResult.Result.Warning)) Warning($ne.line, calleeResult.Result.Warning);
                  
               Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
               MethodRepTemplate calleeMethod = calleeResult.Result as MethodRepTemplate;
               myMap[calleeMethod.Params[0].Name] = wrapArgument($n10.tree, $ne.token);
               myMap[calleeMethod.Params[1].Name] = wrapArgument($n102.tree, $ne.token);
               ret = mkJavaWrapper(calleeMethod.Java, myMap, $ne.token);
               AddToImports(calleeMethod.Imports);
               $dotNetType = calleeResult.ResultType; 
            }
            else {
               WarningFailedResolve($ne.line, "Could not resolve method application of Remove against " + $n10.dotNetType.TypeName);
            }
         }
         $dotNetType = $n10.dotNetType; 
        }
        | ^('*' n11=non_assignment_expression[ObjectType] non_assignment_expression[ObjectType])      {$dotNetType = $n11.dotNetType; }
        | ^('/' n12=non_assignment_expression[ObjectType] non_assignment_expression[ObjectType])      {$dotNetType = $n12.dotNetType; }
        | ^('%' n13=non_assignment_expression[ObjectType] non_assignment_expression[ObjectType])      {$dotNetType = $n13.dotNetType; }
 //       | ^(UNARY_EXPRESSION unary_expression)
        | unary_expression[$typeCtxt]
              {
                $dotNetType = $unary_expression.dotNetType; 
                $rmId = $unary_expression.rmId; 
                $typeofType = $unary_expression.typeofType; 
                $thedottedtext = $unary_expression.thedottedtext; 
              }
	;

///////////////////////////////////////////////////////
//	lambda Section
///////////////////////////////////////////////////////
lambda_expression[TypeRepTemplate typeCtxt] returns [TypeRepTemplate dotNetType]
@init {
   CommonTree ret = null;
}
@after {
    if (ret != null)
        $lambda_expression.tree = ret;
}:
	anonymous_function_signature[$typeCtxt]?   d='=>'   anonymous_function_body
      {
         if ($typeCtxt != null && $typeCtxt is DelegateRepTemplate && $anonymous_function_signature.isTypedParams) {
            // use an anonymous inner class to generate a delegate object (object wih an Invoke with appropriate arguments)
            // new <delegate_name>() { public void Invoke(<formal args>) throw exception <block> }
            DelegateRepTemplate delType = $typeCtxt as DelegateRepTemplate;
            ret = mkDelegateObject((CommonTree)$typeCtxt.Tree, $anonymous_function_signature.tree, $anonymous_function_body.tree, delType, $d.token);
            $dotNetType = $typeCtxt;
         }
      }
   ;
anonymous_function_signature[TypeRepTemplate typeCtxt] returns [bool isTypedParams]
@init {
    $isTypedParams = true;
    CommonTree ret = null;
    List<CommonTree> ids = new List<CommonTree>(); 
}
@after {
    if (ret != null)
        $anonymous_function_signature.tree = ret;
}:
	^(PARAMS fixed_parameter+)
	| ^(p=PARAMS_TYPELESS (identifier { ids.Add($identifier.tree); })+)
      {
         if ($typeCtxt != null && $typeCtxt is DelegateRepTemplate && ids.Count == ((DelegateRepTemplate)$typeCtxt).Invoke.Params.Count) {
            ret = mkTypedParams(((DelegateRepTemplate)$typeCtxt).Invoke.Params, ids, $p.token);
         }
         else {
            $isTypedParams = false;
         }
      }
	;
anonymous_function_body:
	expression[ObjectType] 
      -> {$expression.dotNetType != null && $expression.dotNetType.IsA(VoidType, AppEnv)}? OPEN_BRACE[$expression.tree.Token, "{"] expression SEMI[$expression.tree.Token, ";"] CLOSE_BRACE[$expression.tree.Token, "}"]
      -> OPEN_BRACE[$expression.tree.Token, "{"] ^(RETURN[$expression.tree.Token, "return"] expression) CLOSE_BRACE[$expression.tree.Token, "}"]
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
	'from'   type?   identifier   'in'   expression[ObjectType] ;
join_clause:
	'join'   type?   identifier   'in'   expression[ObjectType]   'on'   expression[ObjectType]   'equals'   expression[ObjectType] ('into' identifier)? ;
let_clause:
	'let'   identifier   '='   expression[ObjectType];
orderby_clause:
	'orderby'   ordering_list ;
ordering_list:
	ordering   (','   ordering)* ;
ordering:
	expression[ObjectType]    ordering_direction
	;
ordering_direction:
	'ascending'
	| 'descending' ;
select_or_group_clause:
	select_clause
	| group_clause ;
select_clause:
	'select'   expression[ObjectType] ;
group_clause:
	'group'   expression[ObjectType]   'by'   expression[ObjectType] ;
where_clause:
	'where'   boolean_expression ;
boolean_expression:
	expression[ObjectType];

///////////////////////////////////////////////////////
// B.2.13 Attributes
///////////////////////////////////////////////////////
global_attributes: 
	global_attribute+ ;
global_attribute: 
	^(GLOBAL_ATTRIBUTE global_attribute_target_specifier   attribute_list);
global_attribute_target_specifier: 
	global_attribute_target   ':' ;
global_attribute_target: 
	'assembly' | 'module' ;
attributes: 
	attribute_sections ;
attribute_sections: 
	attribute_section+ ;
attribute_section: 
	^(ATTRIBUTE attribute_target_specifier?   attribute_list) ;
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
	expression[ObjectType] ;

///////////////////////////////////////////////////////
//	Class Section
///////////////////////////////////////////////////////

class_declaration 
scope NSContext,SymTab;
@init {
    $NSContext::namespaces = new List<string>();
    $NSContext::globalNamespaces = new List<string>(((NSContext_scope)$NSContext.ToArray()[1]).globalNamespaces);
    $NSContext::typeVariables = new List<string>();
    $NSContext::globalTypeVariables = new List<string>(((NSContext_scope)$NSContext.ToArray()[1]).globalTypeVariables);

    $NSContext::IsGenericICollection = false;
    $NSContext::GenericICollectionTyVar = "";
    $NSContext::IsICollection = false;

    $SymTab::symtab = new Dictionary<string, TypeRepTemplate>();
}
:
   ^(c=CLASS  'partial'? PAYLOAD? attributes? modifiers? identifier type_parameter_constraints_clauses? 
        type_parameter_list? 
             { $NSContext::currentNS = NSPrefix(ParentNameSpace) + mkGenericTypeAlias($identifier.thetext, $type_parameter_list.tyParams); if (CompUnitName == null) CompUnitName = $NSContext::currentNS; }
         class_implements? 
         { 
            $NSContext::namespaces.Add($NSContext::currentNS);
            $NSContext::globalNamespaces.Add($NSContext::currentNS);
            if ($type_parameter_list.tyParams != null) {
                $NSContext::typeVariables.AddRange($type_parameter_list.tyParams);
                $NSContext::globalTypeVariables.AddRange($type_parameter_list.tyParams);
            }
            ClassRepTemplate classTypeRep = (ClassRepTemplate)AppEnv.Search($NSContext::currentNS);
			if (classTypeRep == null) {
			    Error($c.line, "Could not find class " + $NSContext::currentNS + " in the type environment");
			}
			else {
				$SymTab::symtab["this"] = classTypeRep;
				ClassRepTemplate baseType = ObjectType;
				if (classTypeRep.Inherits != null && classTypeRep.Inherits.Length > 0) {
					// if Inherits[0] Take first class as super
                   foreach (String super in classTypeRep.Inherits) {
					  ClassRepTemplate parent = AppEnv.Search(classTypeRep.Uses, super, null) as ClassRepTemplate;
                      if (parent != null) {
                        baseType = parent;
                        break;
                      }
                    }    
				}
				$SymTab::symtab["super"] = baseType;
			}
            if ($NSContext::IsICollection) {
                Debug(10, $NSContext::currentNS + " is a Collection");
            }
            if ($NSContext::IsGenericICollection) {
                Debug(10, $NSContext::currentNS + " is a Generic Collection");
            }
         }
         class_body magicAnnotation[$modifiers.tree, $identifier.tree, null, $c.token])
    -> {$class_implements.hasExtends && $class_implements.extendDotNetType.IsA(AppEnv.Search("System.Attribute", new UnknownRepTemplate("System.Attribute")), AppEnv)}? magicAnnotation
    -> ^($c 'partial'? PAYLOAD? attributes? modifiers? identifier type_parameter_constraints_clauses? type_parameter_list? class_implements? class_body);

type_parameter_list returns [List<string> tyParams]
@init {
    $tyParams = new List<string>();
}:
    (attributes? type_parameter { $tyParams.Add($type_parameter.thetext); })+ ;

type_parameter returns [string thetext]:
    identifier { $thetext = $identifier.thetext; };

class_extends:
	class_extend+ ;
class_extend:
	^(EXTENDS type);

// If first implements type is a class then convert to extends
class_implements returns [bool hasExtends, TypeRepTemplate extendDotNetType]
@init {
    CommonTree extends = null; 
}:
	(class_implement_or_extend[extends == null] { if ($class_implement_or_extend.extends != null) {
                                    extends = $class_implement_or_extend.extends;
                                    $hasExtends = true; 
                                    $extendDotNetType = $class_implement_or_extend.extendDotNetType;  
                                  }})+
    ->  { extends } class_implement_or_extend*;

class_implement_or_extend[bool lookingForBase] returns [CommonTree extends, TypeRepTemplate extendDotNetType]
@init {
    $extends = null;
}:
	^(i=IMPLEMENTS t=type  magicExtends[$lookingForBase && $t.dotNetType is ClassRepTemplate, $i.token, $t.tree]
            { if ($lookingForBase && $t.dotNetType is ClassRepTemplate) {
                    $extends = $magicExtends.tree;
                    $extendDotNetType = $t.dotNetType;
                }
               if($t.dotNetType.IsA(ICollectionType,AppEnv)) $NSContext::IsICollection = true; 
               if($t.dotNetType.IsA(GenericICollectionType,AppEnv) && $t.dotNetType.TypeParams.Length > 0) {
                    $NSContext::IsGenericICollection = true;
                    $NSContext::GenericICollectionTyVar = $t.dotNetType.TypeParams[0];
               }
            } ) 
              -> { $lookingForBase && $t.dotNetType is ClassRepTemplate }? 
              -> ^($i $t);
	
class_body
@init {
    CommonTree collectorNodes = null;
    if ($NSContext::IsGenericICollection) {
        collectorNodes = this.parseString("class_member_declarations", Fragments.GenericCollectorMethods($NSContext::GenericICollectionTyVar, $NSContext::GenericICollectionTyVar + "__" + dummyTyVarCtr++));
        AddToImports("java.util.Iterator");
        AddToImports("java.util.Collection");
        AddToImports("java.util.ArrayList");
    }
}:
	'{' class_member_declarations? '}' -> '{' class_member_declarations? { dupTree(collectorNodes) } '}' ;
class_member_declarations:
	class_member_declaration+ ;

///////////////////////////////////////////////////////
constant_declaration:
	'const'   type   constant_declarators[$type.dotNetType]   ';' ;
constant_declarators[TypeRepTemplate ty]:
	constant_declarator[$ty] (',' constant_declarator[$ty])* ;
constant_declarator[TypeRepTemplate ty]:
	identifier  { $SymTab::symtab[$identifier.thetext] = $ty; } ('='   constant_expression[$ty])? ;
constant_expression[TypeRepTemplate tyCtxt] returns [string rmId]:
	expression[$tyCtxt] {$rmId = $expression.rmId; };

///////////////////////////////////////////////////////
field_declaration[CommonTree tyTree, TypeRepTemplate ty]:
	variable_declarators[$tyTree, $ty] ;
variable_declarators[CommonTree tyTree, TypeRepTemplate ty]:
	variable_declarator[$tyTree, $ty] (','   variable_declarator[$tyTree, $ty])* ;
variable_declarator[CommonTree tyTree, TypeRepTemplate ty]
@init {
    bool hasInit = false;
    bool constructStruct = $ty != null && $ty is StructRepTemplate ;
    EnumRepTemplate enumRep = $ty as EnumRepTemplate;
    bool constructEnum = enumRep != null && enumRep.Members.Count > 0;
    string zeroEnum = "WhoopsEnum";
    if (constructEnum)
    {
        zeroEnum = enumRep.Members[0].Name;
    }
}:
	identifier 
       (e='='   variable_initializer[$ty] { hasInit = true; constructStruct = false; constructEnum = false; } )?
        magicConstructStruct[constructStruct, $tyTree, $identifier.tree != null ? $identifier.tree.Token : null]
        magicConstructDefaultEnum[constructEnum, $ty, zeroEnum, $identifier.tree != null ? $identifier.tree.Token : null]
        		// eg. event EventHandler IInterface.VariableName = Foo;
    -> {hasInit}? identifier $e variable_initializer
    -> {constructStruct}? identifier ASSIGN[$identifier.tree.Token, "="] magicConstructStruct
    -> {constructEnum}? identifier ASSIGN[$identifier.tree.Token, "="] magicConstructDefaultEnum
    -> identifier
    ;
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
member_name
@init {
   // in_member_name is used by type_or-generic so that we don't treat the member name as a type.
    string preTy = null;
    bool save_in_member_name = this.in_member_name;
    this.in_member_name = true;
}
@after{
    this.in_member_name = save_in_member_name;
}:
    t1=type_or_generic[""] { preTy = ($t1.dotNetType == null ? "" : $t1.dotNetType.TypeName); }('.' tn=type_or_generic[preTy+"."] { preTy = ($tn.dotNetType == null ? "" : $tn.dotNetType.TypeName); })*
    //(type '.') => type '.' identifier 
    //| identifier
    ;
    // keving: missing interface_type.identifier
	//identifier ;		// IInterface<int>.Method logic added.

///////////////////////////////////////////////////////

event_declaration:
	type member_name   '{'   event_accessor_declarations   '}'
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
	^(ENUM attributes? modifiers?   identifier   enum_base?   enum_body );
enum_base:
	type ;
enum_body:
	^(ENUM_BODY enum_member_declarations?) ;
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

// 4.0
variant_generic_parameter_list returns [List<string> tyParams]
@init {
    $tyParams = new List<string>();
}:
      (variant_type_variable_name {$tyParams.Add($variant_type_variable_name.thetext); })+ ;
variant_type_variable_name returns [string thetext]:
	attributes?   variance_annotation?   type_variable_name { $thetext = $type_variable_name.thetext; };
variance_annotation:
	IN | OUT ;

type_parameter_constraints_clauses:
	type_parameter_constraints_clause+ -> type_parameter_constraints_clause*;
type_parameter_constraints_clause:
    // If there are no type constraints on this variable then drop this constraint
	^(TYPE_PARAM_CONSTRAINT type_variable_name) -> 
    | ^(TYPE_PARAM_CONSTRAINT type_variable_name type_name+) ;
type_variable_name returns [string thetext]: 
	identifier { $thetext = $identifier.thetext; };
constructor_constraint:
	'new'   '('   ')' ;
return_type:
	type ;
formal_parameter_list:
    ^(PARAMS formal_parameter+) ;
formal_parameter:
	attributes?   (fixed_parameter | parameter_array) 
	| '__arglist';	// __arglist is undocumented, see google
//fixed_parameters:
//	fixed_parameter   (','   fixed_parameter)* ;
// 4.0
fixed_parameter
scope PrimitiveRep;
@init {
    $PrimitiveRep::primitiveTypeAsObject = false;
    bool isRefOut = false;
}:
      (parameter_modifier { isRefOut = $parameter_modifier.isRefOut; if (isRefOut) { $PrimitiveRep::primitiveTypeAsObject = true; AddToImports("CS2JNet.JavaSupport.language.RefSupport");} })?   
            type   identifier  { $type.dotNetType.IsWrapped = isRefOut; $SymTab::symtab[$identifier.thetext] = $type.dotNetType; }  default_argument? magicRef[isRefOut, $type.tree != null ? $type.tree.Token : null, $type.tree]
   -> {isRefOut}? magicRef identifier default_argument?
   -> parameter_modifier? type identifier default_argument?
   ;
// 4.0
default_argument:
	'=' expression[ObjectType];
parameter_modifier returns [bool isRefOut]
@init {
   $isRefOut = true;
}:
	'ref' -> | 'out' -> | 'this' { $isRefOut = false;};
parameter_array:
	^(p='params'   type   identifier { $SymTab::symtab[$identifier.thetext] = findType("System.Array", new TypeRepTemplate[] {$type.dotNetType}); }) ;


///////////////////////////////////////////////////////
interface_declaration:
   ^(INTERFACE 'partial'? attributes? modifiers? identifier type_parameter_constraints_clauses?   variant_generic_parameter_list? 
    	class_extends?    interface_body ) ;
interface_modifiers: 
	modifier+ ;
interface_body:
	'{'   interface_member_declarations?   '}' ;
interface_member_declarations:
	interface_member_declaration+ ;
interface_member_declaration
scope SymTab;
@init {
    $SymTab::symtab = new Dictionary<string,TypeRepTemplate>();
}:
    ^(e=EVENT attributes? modifiers? t=type i=identifier magicEventCollectionType[$t.tree.Token, $t.tree] )
      { AddToImports("CS2JNet.JavaSupport.language.IEventCollection"); }
      ->   ^(METHOD[$e.token, "METHOD"] attributes? modifiers? magicEventCollectionType identifier EXCEPTION[$i.tree.Token, "Exception"])
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
    string methodName = "__cast";
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
conversion_operator_declarator returns [ string var, TypeRepTemplate varTy, TypeRepTemplate toTy ] :
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
statement[bool isStatementListCtxt]
scope {
   CommonTree preStatements;
   CommonTree postStatements;
}
@init {
   $statement::preStatements = (CommonTree)adaptor.Nil;
   $statement::postStatements = (CommonTree)adaptor.Nil;
   bool hasPreOrPost = false;
   CommonTree statTree = null;
}:
      ((declaration_statement) => declaration_statement { statTree = dupTree($declaration_statement.tree); }
        | statement_plus[isStatementListCtxt] { statTree = dupTree($statement_plus.tree); }) 
                  { hasPreOrPost = adaptor.GetChildCount($statement::preStatements) > 0 || adaptor.GetChildCount($statement::postStatements) > 0; } 
          -> {isStatementListCtxt || !hasPreOrPost }? { $statement::preStatements } { statTree } { $statement::postStatements }
          -> OPEN_BRACE[statTree.Token, "{"] { $statement::preStatements } { statTree } { $statement::postStatements } CLOSE_BRACE[statTree.Token, "}"]
;
statement_plus[bool isStatementListCtxt]:
    labeled_statement[isStatementListCtxt] 
    | embedded_statement[isStatementListCtxt]
	;
embedded_statement[bool isStatementListCtxt]
@init{
   string idName = null;
   bool emitPrePost = false;
   bool jumpStatementHasExpression = false;
}
@after{
   if(emitPrePost) {
      // reset (just in case) they have already been emitted
      $statement::preStatements = (CommonTree)adaptor.Nil;
      $statement::postStatements = (CommonTree)adaptor.Nil;
   }
}
:
      block
	| ^(ift=IF boolean_expression 
                  { emitPrePost = adaptor.GetChildCount($statement::preStatements) > 0 || adaptor.GetChildCount($statement::postStatements) > 0; 
                    if (emitPrePost) {
                        idName = "boolVar___" + dummyVarCtr++;
                    }
                  } 
            SEP embedded_statement[/* isStatementListCtxt */ false] else_statement?)
            magicType[emitPrePost, $ift.token, "boolean", null]
            magicAssignment[emitPrePost, $ift.token, $magicType.tree, idName, $boolean_expression.tree]
          -> {!emitPrePost }? ^($ift boolean_expression SEP embedded_statement else_statement?)
          -> {isStatementListCtxt}? 
                 { $statement::preStatements } magicAssignment  { $statement::postStatements } ^($ift IDENTIFIER[$ift.token, idName] SEP embedded_statement else_statement?)
          -> OPEN_BRACE[$ift.token, "{"] { $statement::preStatements } magicAssignment  { $statement::postStatements } ^($ift IDENTIFIER[$ift.token, idName] SEP embedded_statement else_statement?) CLOSE_BRACE[$ift.token, "}"]
    | switch_statement[isStatementListCtxt]
	| iteration_statement	// while, do, for, foreach
	| jump_statement
    | 	(^(('return' | 'throw') expression[ObjectType]?)) => (^(jt='return' (je=expression[ObjectType] {jumpStatementHasExpression = true;})?) | ^(jt='throw' (je=expression[ObjectType]{ jumpStatementHasExpression = true; })?)) 
	     { emitPrePost = adaptor.GetChildCount($statement::preStatements) > 0 || adaptor.GetChildCount($statement::postStatements) > 0;
           if (emitPrePost) {
              idName = "resVar___" + dummyVarCtr++;
           }
         }
         magicAssignment[emitPrePost, $jt.token, jumpStatementHasExpression ? ($je.dotNetType != null ? (CommonTree)$je.dotNetType.Tree : null) : null, idName, $je.tree]
                // jump_statement transfers control, so we ignore any poststatements
          -> {!emitPrePost }? ^($jt $je?)
          -> {isStatementListCtxt}? { $statement::preStatements } magicAssignment { $statement::postStatements } ^($jt IDENTIFIER[$jt.token, idName])
          -> OPEN_BRACE[$jt.token, "{"] { $statement::preStatements } magicAssignment { $statement::postStatements } ^($jt IDENTIFIER[$jt.token, idName]) CLOSE_BRACE[$jt.token, "}"]	

       // break, continue, goto, return, throw
	| ^('try' block catch_clauses? finally_clause?)
	| checked_statement
	| unchecked_statement
	| lock_statement
    | yield_statement
    | ^('unsafe'   block)
	| fixed_statement
	| expression_statement  { emitPrePost = adaptor.GetChildCount($statement::preStatements) > 0 || adaptor.GetChildCount($statement::postStatements) > 0; }
          -> {!emitPrePost }? expression_statement
          -> {isStatementListCtxt}? { $statement::preStatements } expression_statement  { $statement::postStatements }
          -> OPEN_BRACE[$expression_statement.tree.Token, "{"] { $statement::preStatements } expression_statement  { $statement::postStatements } CLOSE_BRACE[$expression_statement.tree.Token, "}"]
    // expression!
	;
switch_statement[ bool isStatementListCtxt]
scope {
    bool isEnum;
    bool convertToIfThenElse;
    string scrutVar;
    bool isFirstCase;
    CommonTree defaultTree;
}
@init {
    $switch_statement::isEnum = false;
    $switch_statement::convertToIfThenElse = false;
    $switch_statement::scrutVar = "WHOOPS";
    $switch_statement::isFirstCase = true;
    $switch_statement::defaultTree = null;
}:
    ^(s='switch' se=expression[ObjectType] sv=magicScrutineeVar[$s.token]
                { 
                    if ($expression.dotNetType != null) {
                        $switch_statement::isEnum = $expression.dotNetType.IsA(AppEnv.Search("System.Enum"), AppEnv); 
                        $switch_statement::convertToIfThenElse = typeIsInvalidForScrutinee($expression.dotNetType);
                        $switch_statement::scrutVar = $sv.thetext;
                    }
                } 
            ss+=switch_section*) 
        -> { $switch_statement::convertToIfThenElse && isStatementListCtxt }?
                // TYPE{ String } ret ;
                ^(TYPE[$s.token, "TYPE"] IDENTIFIER[$s.token,$expression.dotNetType.Java]) $sv ASSIGN[$s.token, "="] { dupTree($se.tree) } SEMI[$s.token, ";"]
                { convertSectionsToITE($ss, $switch_statement::defaultTree) } 
        -> { $switch_statement::convertToIfThenElse }?
                // TYPE{ String } ret ;
                OPEN_BRACE[$s.token, "{"]
                ^(TYPE[$s.token, "TYPE"] IDENTIFIER[$s.token,$expression.dotNetType.Java]) $sv ASSIGN[$s.token, "="] { dupTree($se.tree) } SEMI[$s.token, ";"]
                { convertSectionsToITE($ss, $switch_statement::defaultTree) } 
                CLOSE_BRACE[$s.token, "}"]
        -> ^($s expression $ss*) 
    ;
fixed_statement:
	'fixed'   '('   pointer_type fixed_pointer_declarators   ')'   embedded_statement[ /* isStatementListCtxt */ false] ;
fixed_pointer_declarators:
	fixed_pointer_declarator   (','   fixed_pointer_declarator)* ;
fixed_pointer_declarator:
	identifier   '='   fixed_pointer_initializer ;
fixed_pointer_initializer:
	//'&'   variable_reference   // unary_expression covers this
	expression[ObjectType];
labeled_statement[bool isStatementListCtxt]:
	identifier ':' statement[isStatementListCtxt] ;
declaration_statement:
	(local_variable_declaration 
	| local_constant_declaration) ';' ;
local_variable_declaration:
	local_variable_type   local_variable_declarators[$local_variable_type.tree, $local_variable_type.dotNetType, $local_variable_type.isVar] 
       { 
           if ($local_variable_type.isVar && $local_variable_declarators.bestTy != null && !$local_variable_declarators.bestTy.IsUnknownType) {
              foreach (string id in  $local_variable_declarators.identifiers) {
                  $SymTab::symtab[id] = $local_variable_declarators.bestTy; 
              }
           } 
    }
    -> {$local_variable_type.isVar && $local_variable_declarators.bestTy != null && !$local_variable_declarators.bestTy.IsUnknownType}? 
         ^(TYPE[$local_variable_type.tree.Token, "TYPE"] IDENTIFIER[$local_variable_type.tree.Token, $local_variable_declarators.bestTy.mkFormattedTypeName(false, "<",">")]) local_variable_declarators
    -> local_variable_type   local_variable_declarators
;
local_variable_type returns [bool isTypeNode, bool isVar, TypeRepTemplate dotNetType]
@init {
   $isTypeNode = false;
   $isVar = false;
}:
	TYPE_VAR                     { $dotNetType = new UnknownRepTemplate("System.Object"); $isVar = true;}
	| TYPE_DYNAMIC               { $dotNetType = new UnknownRepTemplate("System.Object"); }
	| type                       { $dotNetType = $type.dotNetType; $isTypeNode = true; };
local_variable_declarators[CommonTree tyTree, TypeRepTemplate ty, bool isVar] returns [TypeRepTemplate bestTy, List<String> identifiers]
@init {
   $identifiers = new List<String>();
}:
	d1=local_variable_declarator[$tyTree, $ty] { $identifiers.Add($d1.identifier); if ($isVar) $bestTy = $d1.dotNetType; } 
        (',' dn=local_variable_declarator[$tyTree, $ty] 
         {
            $identifiers.Add($d1.identifier);
            if ($isVar) {
               if (!$dn.dotNetType.IsUnknownType && $bestTy.IsA($dn.dotNetType, AppEnv)) {
                  $bestTy = $dn.dotNetType;
               }
            }
         }
        )* ;
local_variable_declarator[CommonTree tyTree, TypeRepTemplate ty] returns [TypeRepTemplate dotNetType, String identifier]
@init {
    bool hasInit = false;
    bool constructStruct = $ty != null && $ty is StructRepTemplate ;
    EnumRepTemplate enumRep = $ty as EnumRepTemplate;
    bool constructEnum = enumRep != null && enumRep.Members.Count > 0;
    string zeroEnum = "WhoopsEnum";
    if (constructEnum)
    {
        zeroEnum = enumRep.Members[0].Name;
    }
}:
	i=identifier { $identifier = $i.thetext; $SymTab::symtab[$i.thetext] = $ty; } 
       (e='='   local_variable_initializer[$ty ?? ObjectType] { hasInit = true; constructStruct = false; constructEnum = false; $dotNetType = $local_variable_initializer.dotNetType; } )?
        magicConstructStruct[constructStruct, $tyTree, ($i.tree != null ? $i.tree.Token : null)]
        magicConstructDefaultEnum[constructEnum, $ty, zeroEnum, $identifier.tree != null ? $identifier.tree.Token : null]
        		// eg. event EventHandler IInterface.VariableName = Foo;
    -> {hasInit}? $i $e local_variable_initializer
    -> {constructStruct}? $i ASSIGN[$i.tree.Token, "="] magicConstructStruct
    -> {constructEnum}? $i ASSIGN[$i.tree.Token, "="] magicConstructDefaultEnum
    -> $i
    ;
local_variable_initializer[TypeRepTemplate typeCtxt] returns [TypeRepTemplate dotNetType]
@init {
   $dotNetType = ObjectType;
}:
	expression[$typeCtxt] { $dotNetType = $expression.dotNetType; }
	| array_initializer 
	| stackalloc_initializer;
stackalloc_initializer:
	'stackalloc'   unmanaged_type   '['   expression[ObjectType]   ']' ;
local_constant_declaration:
	'const'   type   constant_declarators[$type.dotNetType] ;
expression_statement:
	expression[ObjectType]   ';' ;

// TODO: should be assignment, call, increment, decrement, and new object expressions
statement_expression:
	expression[ObjectType]
	;
else_statement:
	'else'   embedded_statement[/* isStatementListCtxt */ false]	;
switch_section
@init {
    bool defaultSection = false;
    bool isFirstCase = $switch_statement::isFirstCase;
}
:
	^(s=SWITCH_SECTION ({$switch_statement::convertToIfThenElse}? ite_switch_labels | switch_labels) sl=statement_list 
         { if ($switch_statement::convertToIfThenElse && $ite_switch_labels.isDefault) {
               $switch_statement::defaultTree = stripFinalBreak($sl.tree);
            } else {
               $switch_statement::isFirstCase = false;
            }
          }
      ) 

    -> {$switch_statement::convertToIfThenElse && $ite_switch_labels.isDefault}?
//    -> {$switch_statement::convertToIfThenElse && $ite_switch_labels.isDefault}? ELSE[$s.token, "else"]  OPEN_BRACE[$s.token, "{"] { stripFinalBreak($sl.tree) } CLOSE_BRACE[$s.token, "}"] 
    -> {$switch_statement::convertToIfThenElse && isFirstCase}? ^(IF[$s.token, "if"]  ite_switch_labels SEP OPEN_BRACE[$s.token, "{"] { stripFinalBreak($sl.tree) } CLOSE_BRACE[$s.token, "}"])
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
    ^(c='case'  ce=constant_expression[ObjectType] ) 
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

    TypeRepTemplate exprType = null;
    TypeRepTemplate elType = null;
}
@after {
    if (ret != null)
        $iteration_statement.tree = ret;
}:
	^('while' boolean_expression SEP embedded_statement[/* isStatementListCtxt */ false])
	| do_statement
	| ^('for' for_initializer? SEP for_condition? SEP for_iterator? SEP embedded_statement[/* isStatementListCtxt */ false])
	| ^(f='foreach' local_variable_type   identifier expression[ObjectType] s=SEP  
         { 
            newExpression = $expression.tree;
            exprType = $expression.dotNetType;
            if (exprType != null) {
                ResolveResult iterable = exprType.ResolveIterable(AppEnv);
                if (iterable != null) {
                    if (!String.IsNullOrEmpty(iterable.Result.Warning)) Warning($expression.tree.Token.Line, iterable.Result.Warning);
                    Dictionary<string,CommonTree> myMap = new Dictionary<string,CommonTree>();
                    myMap["expr"] = wrapExpression($expression.tree, $expression.tree.Token);
                    newExpression = mkJavaWrapper(iterable.Result.Java, myMap, $expression.tree.Token);
                    AddToImports(iterable.Result.Imports);
                    elType = iterable.ResultType;
                }
            }
            // Set identifier type in symbol table
            if ($local_variable_type.isVar && elType != null) {
               $SymTab::symtab[$identifier.thetext] = elType;
            }
            else {
               $SymTab::symtab[$identifier.thetext] = $local_variable_type.dotNetType; 
            }
        }  
         embedded_statement[/* isStatementListCtxt */ false])
           magicTypeFromTemplate[$local_variable_type.isVar && elType != null, $f.token, elType] magicObjectType[$f.token] magicForeachVar[$f.token]
        {
            newType = $local_variable_type.tree;
            newIdentifier = $identifier.tree;
            newEmbeddedStatement = $embedded_statement.tree;
            
            bool needCast = true;
            if ($local_variable_type.isVar) {
               // If local_type is dynamic then just leave it there, 
               if (elType != null) {
                  newType = $magicTypeFromTemplate.tree;
               }
               needCast = false;
            }
            else {
               if (elType != null && $local_variable_type.dotNetType != null) {
                  if (elType.IsA($local_variable_type.dotNetType, AppEnv)) {
                     needCast = false;
                  }
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
	'do'   embedded_statement[/* isStatementListCtxt */ false]   'while'   '('   boolean_expression   ')'   ';' ;
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
;
break_statement:
	'break'   ';' ;
continue_statement:
	'continue'   ';' ;
goto_statement:
	'goto'   ( identifier
			 | 'case'   constant_expression[ObjectType]
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
	^(UNCHECKED block) ;
lock_statement:
	'lock'   '('  expression[ObjectType]   ')'   embedded_statement[/* isStatementListCtxt */ false] ;

yield_statement:
    ^(YIELD_RETURN expression[ObjectType])
    | YIELD_BREAK ;

///////////////////////////////////////////////////////
//	Lexar Section
///////////////////////////////////////////////////////

predefined_type returns [TypeRepTemplate dotNetType]
@init {
    string ns = "";
}
@after {
    $dotNetType = new ClassRepTemplate((ClassRepTemplate)AppEnv.Search(ns, new UnknownRepTemplate(ns)));
    $dotNetType.IsUnboxedType = true;
    string newText = null;
    if (primitive_to_object_type_map.TryGetValue($predefined_type.tree.Token.Text, out newText))
       $dotNetType.BoxedName = newText;

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
    | 'uint'    { ns =  Cfg.UnsignedNumbersToSigned ? "System.Int32" : "System.UInt32"; }
    | 'ulong'   { ns =  Cfg.UnsignedNumbersToSigned ? "System.Int64" : "System.UInt64"; }
    | 'ushort'  { ns =  Cfg.UnsignedNumbersToSigned ? "System.Int16" : "System.UInt16"; }
    ;

// Don't trust identifier.text in tree grammars: Doesn't work for our magic additions because the text function goes back to the 
// original token stream to make up the text for a tree node 
identifier returns [string thetext]:
 	IDENTIFIER { $thetext = $IDENTIFIER.text; } | also_keyword { $thetext = $also_keyword.text; };  // might need to return text from also_keyword too if we start manufacturing those  

keyword:
	'abstract' | 'as' | 'base' | 'bool' | 'break' | 'byte' | 'case' |  'catch' | 'char' | 'checked' | 'class' | 'const' | 'continue' | 'decimal' | 'default' | 'delegate' | 'do' |	'double' | 'else' |	 'enum'  | 'event' | 'explicit' | 'extern' | 'false' | 'finally' | 'fixed' | 'float' | 'for' | 'foreach' | 'goto' | 'if' | 'implicit' | 'in' | 'int' | 'interface' | 'internal' | 'is' | 'lock' | 'long' | 'namespace' | 'new' | 'null' | 'object' | 'operator' | 'out' | 'override' | 'params' | 'private' | 'protected' | 'public' | 'readonly' | 'ref' | 'return' | 'sbyte' | 'sealed' | 'short' | 'sizeof' | 'stackalloc' | 'static' | 'string' | 'struct' | 'switch' | 'this' | 'throw' | 'true' | 'try' | 'typeof' | 'uint' | 'ulong' | 'unchecked' | 'unsafe' | 'ushort' | 'using' | 'virtual' | 'void' | 'volatile' ;

also_keyword:
	'add' | 'alias' | 'assembly' | 'module' | 'field' | 'method' | 'param' | 'property' | 'type' | 'yield'
	| 'from' | 'into' | 'join' | 'on' | 'where' | 'orderby' | 'group' | 'by' | 'ascending' | 'descending' 
	| 'equals' | 'select' | 'pragma' | 'let' | 'remove' | 'get' | 'set' | 'var' | '__arglist' | 'dynamic' | 'elif' 
	| 'endif' | 'define' | 'undef' | 'extends';

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
	Real_literal                { ns = "System.Double"; }
	| NUMBER                    { ns = "System.Int32"; }
	| LONGNUMBER                { ns = "System.Int64"; }
	| Hex_number                { ns = "System.Int32"; }
	| Character_literal         { ns = "System.Char"; }
	| STRINGLITERAL             { ns = "System.String"; }
	| Verbatim_string_literal   { ns = "System.String"; }
	| TRUE                      { ns = "System.Boolean"; }
	| FALSE                     { ns = "System.Boolean"; }
	| NULL                      { ns = "System.Object"; isNull = true; }
	;

magicScrutineeVar [IToken tok] returns [string thetext]
@init {
    $thetext = "__dummyScrutVar" + dummyScrutVarCtr++;
}:
  -> IDENTIFIER[tok,$thetext];

magicForeachVar [IToken tok] returns [string thetext]
@init {
    $thetext = "__dummyForeachVar" + dummyForeachVarCtr++;
}:
  -> IDENTIFIER[tok,$thetext];

magicObjectType [IToken tok]:
  -> ^(TYPE[tok, "TYPE"] OBJECT[tok, "Object"]);

magicCastOperator[CommonTree mods, string methodName, CommonTree header, CommonTree body]
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
      EXCEPTION[tok, Cfg.TranslatorExceptionIsThrowable ? "Throwable" : "Exception"])
;

magicAnnotation [CommonTree mods, CommonTree name, CommonTree body, IToken tok]:
  -> ^(ANNOTATION[tok, "ANNOTATION"] { dupTree($mods) } { dupTree($name) } { dupTree(body) });

magicSupportOp[bool isOn, string supportlib, string op, CommonTree e1, CommonTree e2, IToken tok]:
  -> { isOn }? 
     ^(APPLY[tok, "APPLY"] ^(DOT[tok,"."] IDENTIFIER[tok,supportlib] IDENTIFIER[tok,op]) ^(ARGS[tok, "ARGS"] { dupTree($e1) } { dupTree($e2) } ) ) 
  -> 
;

magicNegate[bool isOn, CommonTree e, IToken tok]:
  -> { isOn }? 
     ^(MONONOT[tok, "!"] { dupTree($e) }) 
  -> 
;

magicConstructStruct[bool isOn, CommonTree ty, IToken tok]:
   -> { isOn }? ^(NEW[tok, "NEW"] { dupTree(ty) } )
   -> 
;
magicConstructDefaultEnum[bool isOn, TypeRepTemplate ty, string zero, IToken tok]:
   -> { isOn }? ^(DOT[tok, "."] IDENTIFIER[tok, ty.Java] IDENTIFIER[tok, zero]) 
   -> 
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

magicCatchVar:
  -> IDENTIFIER["__dummyStaticConstructorCatchVar" + dummyStaticConstructorCatchVarCtr++];

magicThrowableType[bool isOn, IToken tok]:
 -> {isOn}? ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, Cfg.TranslatorExceptionIsThrowable ? "Throwable" : "Exception"])
 -> 
;

magicEventCollectionType[IToken tok, CommonTree type]:
  -> ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "IEventCollection"] LTHAN[tok, "<"] { dupTree(type) } GT[tok, ">"] )
;

// METHOD{ public TYPE{ Iterator < TYPE{ JAVAWRAPPER{ T } } > } kiterator { TYPE{ Iterator < TYPE{ JAVAWRAPPER{ T } } > } ret = null ; try{ { ret = APPLY{ .{ JAVAWRAPPER{ ${this:16}.GetEnumerator() this EXPRESSION{ this } } iterator } } ; } catch{ TYPE{ JAVAWRAPPER{ Exception } } e { APPLY{ .{ e printStackTrace } } ; } } } return{ ret } } Exception }
//

magicXXGenericIterator[bool isOn, IToken tok, String tyVar]
@init {
   if (isOn) AddToImports("java.util.Iterator");
}
:
->    {isOn}? ^(METHOD[tok, "METHOD"]
                PUBLIC[tok, "public"]
                ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "Iterator"] LTHAN[tok, "<"] ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, tyVar]) GT[tok, ">"])
                IDENTIFIER[tok, "iterator"] 
                OPEN_BRACE[tok, "{"]
                // Iterator<T> ret = null;
                ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "Iterator"] LTHAN[tok, "<"] ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, tyVar]) GT[tok, ">"]) IDENTIFIER[tok, "ret"] ASSIGN[tok,"="] NULL[tok,"null"] SEMI[tok, ";"]
                // try { ret = this.GetEnumerator().iterator(); } catch (Exception e) { e.printstackTrace(); }}
                ^(TRY[tok, "try"]
                    OPEN_BRACE[tok, "{"]
                      IDENTIFIER[tok, "ret"] ASSIGN[tok,"="] ^(APPLY[tok, "APPLY"] ^(DOT[tok, "."] ^(APPLY[tok, "APPLY"] ^(DOT[tok, "."] THIS[tok, "this"] IDENTIFIER[tok, "GetEnumerator"])) IDENTIFIER[tok,"iterator"])) SEMI[tok,";"]
                    CLOSE_BRACE[tok, "}"]
                    ^(CATCH[tok, "catch"] ^(TYPE[tok,"TYPE"] IDENTIFIER[tok, "Exception"]) IDENTIFIER[tok, "e"] 
                       OPEN_BRACE[tok, "{"]
                         ^(APPLY[tok, "APPLY"] ^(DOT[tok, "."] IDENTIFIER[tok, "e"] IDENTIFIER[tok,"printStackTrace"])) SEMI[tok,";"]
                       CLOSE_BRACE[tok, "}"]
                     )
                )
                // return ret;
                ^(RETURN[tok, "return"] IDENTIFIER[tok, "ret"]) 
                CLOSE_BRACE[tok, "}"]
                )
                
->
;

//                       IDENTIFIER[tok, "ret"] ASSIGN[tok,"="] ^(APPLY[tok, "APPLY"] ^(DOT[tok, "."] ^(APPLY[tok, "APPLY"] ^(DOT[tok, "."] THIS[tok, "this"] IDENTIFIER[tok, "GetEnumerator"])) IDENTIFIER[tok,"iterator"])) SEMI[tok,";"]

magicGenericIterator[bool isOn, IToken tok, String tyVar]
@init {
   if (isOn) AddToImports("java.util.Iterator");
}
: 
   magicType[isOn, tok, "Iterator", new string[\] {tyVar}]
   n=magicToken[isOn, tok, NULL, "null"]
   magicAssignment[isOn, tok, $magicType.tree, "ret", $n.tree]

   thisT=magicToken[isOn, tok, THIS, "this"]
   thisEnum=magicDot[isOn, tok, $thisT.tree, "GetEnumerator"]
   mkIter=magicDot[isOn, tok, $thisEnum.tree, "iterator"]
   tryBody=magicApply[isOn, tok, $mkIter.tree, null]

   magicTryCatch[isOn, tok, $tryBody.tree]

   magicMethod[isOn, tok, "iterator", $magicType.tree, null, $magicTryCatch.tree]

->    {isOn}? magicMethod
->
;

magicIterator[bool isOn, IToken tok]
@init {
   if (isOn) AddToImports("java.util.Iterator");
}
: 
   magicType[isOn, tok, "Iterator", null]
   n=magicToken[isOn, tok, NULL, "null"]
   magicAssignment[isOn, tok, $magicType.tree, "ret", $n.tree]
//   magicSmotherExceptions[isOn, tok, ]
   magicMethod[isOn, tok, "iterator", $magicType.tree, null, $magicAssignment.tree]
->    {isOn}? magicMethod
//   ^(METHOD[tok, "METHOD"]
//                 PUBLIC[tok, "public"]
//                 ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "Iterator"])
//                 IDENTIFIER[tok, "iterator"] 
//                 OPEN_BRACE[tok, "{"]
//                 // Iterator ret = null;
//                 ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "Iterator"]) IDENTIFIER[tok, "ret"] ASSIGN[tok,"="] NULL[tok,"null"] SEMI[tok, ";"]
//                 // try { ret = this.GetEnumerator().iterator(); } catch (Exception e) { e.printstackTrace(); }}
//                 ^(TRY[tok, "try"]
//                     OPEN_BRACE[tok, "{"]
//                       IDENTIFIER[tok, "ret"] ASSIGN[tok,"="] ^(APPLY[tok, "APPLY"] ^(DOT[tok, "."] ^(APPLY[tok, "APPLY"] ^(DOT[tok, "."] THIS[tok, "this"] IDENTIFIER[tok, "GetEnumerator"])) IDENTIFIER[tok,"iterator"])) SEMI[tok,";"]
//                     CLOSE_BRACE[tok, "}"]
//                     ^(CATCH[tok, "catch"] ^(TYPE[tok,"TYPE"] IDENTIFIER[tok, "Exception"]) IDENTIFIER[tok, "e"] 
//                        OPEN_BRACE[tok, "{"]
//                          ^(APPLY[tok, "APPLY"] ^(DOT[tok, "."] IDENTIFIER[tok, "e"] IDENTIFIER[tok,"printStackTrace"])) SEMI[tok,";"]
//                        CLOSE_BRACE[tok, "}"]
//                      )
//                 )
//                 // return ret;
//                 ^(RETURN[tok, "return"] IDENTIFIER[tok, "ret"]) 
//                 CLOSE_BRACE[tok, "}"]
//                 )
//                 
->
;

magicToken[bool isOn, IToken tok, int tokenType, string text]
@init {
   CommonTree ret = null;
   if (isOn)
     ret = (CommonTree)adaptor.Create(tokenType, tok, text);
}:
-> {isOn}? { ret }
->
;

// public <retType> <name> <args> { <body> }
magicMethod[bool isOn, IToken tok, string name, CommonTree retType, CommonTree args, CommonTree body]:
-> {isOn}? 
            ^(METHOD[tok, "METHOD"]
                PUBLIC[tok, "public"]
                { dupTree(retType) }
                IDENTIFIER[tok, name] 
                { dupTree(args) }
                OPEN_BRACE[tok, "{"]
                { dupTree(body) }
                CLOSE_BRACE[tok, "}"]
             )
->
;

magicType[bool isOn, IToken tok, string name, string[\] args]
@init {
   CommonTree argsTree = null;
   if (args != null && args.Length > 0) {
      CommonTree root = (CommonTree)adaptor.Nil;
      adaptor.AddChild(root, (CommonTree)adaptor.Create(LTHAN, tok, "<"));
      foreach (string a in args) {
        CommonTree root0 = (CommonTree)adaptor.Nil;
        root0 = (CommonTree)adaptor.BecomeRoot((CommonTree)adaptor.Create(TYPE, tok, "TYPE"), root0);
        adaptor.AddChild(root0, (CommonTree)adaptor.Create(IDENTIFIER, tok, a));
        adaptor.AddChild(root, root0);
      }
      adaptor.AddChild(root, (CommonTree)adaptor.Create(GT, tok, ">"));
      argsTree = (CommonTree)adaptor.RulePostProcessing(root);
   }
}
:
-> {isOn}? 
            ^(TYPE[tok, "TYPE"]
                IDENTIFIER[tok, name]
                { dupTree(argsTree) }
             )
->
;

// <type>? <name> = exp ;
magicAssignment[bool isOn, IToken tok, CommonTree type, string name, CommonTree exp]:
-> {isOn}? 
                { dupTree(type) }
                IDENTIFIER[tok, name] 
                ASSIGN[tok, "="] 
                { dupTree(exp) }
                SEMI[tok, ";"]
->
;

magicTryCatch[bool isOn, IToken tok, CommonTree body]:
-> {isOn}?
                 ^(TRY[tok, "try"]
                     OPEN_BRACE[tok, "{"]
                     { dupTree(body) }
                     CLOSE_BRACE[tok, "}"]
                     ^(CATCH[tok, "catch"] ^(TYPE[tok,"TYPE"] IDENTIFIER[tok, "Exception"]) IDENTIFIER[tok, "e"] 
                        OPEN_BRACE[tok, "{"]
                          ^(APPLY[tok, "APPLY"] ^(DOT[tok, "."] IDENTIFIER[tok, "e"] IDENTIFIER[tok,"printStackTrace"])) SEMI[tok,";"]
                        CLOSE_BRACE[tok, "}"]
                      )
                  )
-> 
;

magicDot[bool isOn, IToken tok, CommonTree lhs, string rhs]:
-> {isOn}?  ^(DOT[tok, "."] { dupTree(lhs) } IDENTIFIER[tok, rhs])
-> 
;

magicApply[bool isOn, IToken tok, CommonTree methodExp, CommonTree args]:
-> {isOn}?  ^(APPLY[tok, "APPLY"] { dupTree(methodExp) } { dupTree(args) })
-> 
;
    
magicRef[bool isOn, IToken tok, CommonTree ty]:
-> {isOn}?  ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "RefSupport"] LTHAN[tok, "<"] { dupTree(ty) } GT[tok, ">"])
-> 
;

magicCreateRefVar[IToken tok, String id, CommonTree type, CommonTree value]:
-> { type == null }? ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "RefSupport"]) IDENTIFIER[tok, id] ASSIGN[tok, "="] 
       ^(NEW[tok, "new"] ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "RefSupport"]) ^(ARGS[tok, "ARGS"] { dupTree(value) }))
    SEMI[tok,";"]
-> ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "RefSupport"] LTHAN[tok, "<"] { dupTree(type) } GT[tok, ">"]) IDENTIFIER[tok, id] ASSIGN[tok, "="] 
       ^(NEW[tok, "new"] ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "RefSupport"] LTHAN[tok, "<"] { dupTree(type) } GT[tok, ">"]) ^(ARGS[tok, "ARGS"] { dupTree(value) }))
    SEMI[tok,";"]
;

magicCreateOutVar[IToken tok, String id, CommonTree type]:
-> {type == null}? ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "RefSupport"]) IDENTIFIER[tok, id] ASSIGN[tok, "="] 
       ^(NEW[tok, "new"] ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "RefSupport"]))
    SEMI[tok,";"]
-> ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "RefSupport"] LTHAN[tok, "<"] { dupTree(type) } GT[tok, ">"]) IDENTIFIER[tok, id] ASSIGN[tok, "="] 
       ^(NEW[tok, "new"] ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, "RefSupport"] LTHAN[tok, "<"] { dupTree(type) } GT[tok, ">"]))
    SEMI[tok,";"]
;

magicUpdateFromRefVar[IToken tok, String id, CommonTree variable_ref, bool isWrapped]:
-> {isWrapped}? ^(APPLY[tok, "APPLY"] ^(DOT[tok, "."] { dupTree((CommonTree)adaptor.GetChild((CommonTree)adaptor.GetChild(variable_ref, 2),0)) } IDENTIFIER[tok, "setValue"]) ^(ARGS[tok, "ARGS"] ^(APPLY[tok, "APPLY"] ^(DOT[tok, "."] IDENTIFIER[tok, id] IDENTIFIER[tok, "getValue"]) ))) SEMI[tok,";"]
-> { dupTree(variable_ref) } ASSIGN[tok, "="] ^(APPLY[tok, "APPLY"] ^(DOT[tok, "."] IDENTIFIER[tok, id] IDENTIFIER[tok, "getValue"])) SEMI[tok,";"]
;

magicBoxedType[bool isOn, IToken tok, String boxedName]:
    -> { isOn }? ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, boxedName])
    ->
;

magicInputPeId[CommonTree dotTree, CommonTree idTree, CommonTree galTree]:
    -> { dotTree != null}? {dupTree(dotTree)} 
    -> {dupTree(idTree)} { dupTree(galTree) }
;

magicTypeFromTemplate[bool isOn, IToken tok, TypeRepTemplate dotNetType]:
   -> { $isOn && $dotNetType.Tree != null}? { dupTree((CommonTree)$dotNetType.Tree) }
   -> { $isOn }? ^(TYPE[tok, "TYPE"] IDENTIFIER[tok, $dotNetType.mkFormattedTypeName(false, "<",">")])  
   ->
   ;

magicExtends[bool isOn, IToken tok, CommonTree type]:
 -> { $isOn }? ^(EXTENDS[tok, "extends"] { dupTree($type) })
 ->
   ;
