using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Reflection;

using Antlr.Runtime.Tree;
using Antlr.Runtime;

using AntlrCSharp;

using Twiglet.CS2J.Translator.Utils;
using Twiglet.CS2J.Translator.TypeRep;
using Twiglet.CS2J.Translator;

namespace Twiglet.CS2J.Translator.Transform
{
    public class CommonWalker : TreeParser
    {
       // CONSTANTS

       // Max size of enum structure we will generate to match enums to arbitrary integer values
       public const int MAX_DUMMY_ENUMS = 500;


        public CS2JSettings Cfg { get; set; }
        public string Filename { get; set; }

        // AppEnv contains a summary of the environment within which we are translating, it maps fully qualified type names to their
        // translation templates (i.e. a description of their public features)
        public DirectoryHT<TypeRepTemplate> AppEnv {get; set;}


        protected CommonWalker(ITreeNodeStream input, RecognizerSharedState state)
            : base(input, state)
        { }

        protected void Error(int line, String s)
        {
            Console.Error.WriteLine("{0}({1}) error: {2}", Filename, line, s);
        }

        protected void Error(String s)
        {
            Console.Error.WriteLine("{0} error: {1}", Filename, s);
        }

        protected void Warning(int line, String s)
        {
            if (Cfg.Warnings)
                Console.Out.WriteLine("{0}({1}) warning: {2}", Filename, line, s);
        }

        protected void Warning(String s)
        {
            if (Cfg.Warnings)
                Console.Out.WriteLine("{0} warning: {1}", Filename, s);
        }

        protected void WarningAssert(bool assertion, int line, String s)
        {
            if (Cfg.Warnings && !assertion)
                Console.Out.WriteLine("{0}({1}) failed assertion: {2}", Filename, line, s);
        }

        protected void WarningAssert(bool assertion, String s)
        {
            if (Cfg.Warnings && !assertion)
                Console.Out.WriteLine("{0} failed assertion: {1}", Filename, s);
        }

        protected void WarningFailedResolve(int line, String s)
        {
            if (Cfg.WarningsFailedResolves)
               Console.Out.WriteLine("{0}({1}) warning: {2}", Filename, line, s);
        }

        protected void Debug(String s)
        {
            Debug(1, s);
        }

        protected void DebugDetail(string s)
        {
            Debug(5, s);
        }

        protected void Debug(int level, String s)
        {
            if (level <= Cfg.DebugLevel)
            {
                Console.Out.WriteLine(s);
            }
        }

        // distinguish classes with same name, but differing numbers of type arguments
        // Dictionary<K,V> -> Dictionary'2
        protected string mkGenericTypeAlias (string name, List<String> tyargs) {
            return mkGenericTypeAlias(name, tyargs == null ? 0 : tyargs.Count);
        }
        
        protected string mkGenericTypeAlias (string name, int tyargCount) {
            return name + (tyargCount > 0 ? "'" + tyargCount.ToString() : "");
        }
        
        protected string formatTyargs(List<string> tyargs) {
               
            if (tyargs.Count == 0) {
                return "";
            }
            StringBuilder buf = new StringBuilder();
            buf.Append("<");
            foreach (string t in tyargs) {
                buf.Append(t + ",");
            }
            buf.Remove(buf.Length-1,1);
            buf.Append(">");
            return buf.ToString();
        }

        //  Unless empty return current namespace suffixed with "."
        protected string NSPrefix(string ns) {
            return (String.IsNullOrEmpty(ns) ? "" : ns + ".");
        }

        // Routines to parse strings to ANTLR Trees on the fly, used to generate fragments needed by the transformation
       public CommonTree parseString(string startRule, string inStr)
       {
            
          if (Cfg.Verbosity > 5) Console.WriteLine("Parsing fragment ");
            
          ICharStream input = new ANTLRStringStream(inStr);

          PreProcessor lex = new PreProcessor();
          lex.AddDefine(Cfg.MacroDefines);
          lex.CharStream = input;
          lex.TraceDestination = Console.Error;

          CommonTokenStream tokens = new CommonTokenStream(lex);

          csParser p = new csParser(tokens);
          p.TraceDestination = Console.Error;
          p.IsJavaish = true;
			
          // Try and call a rule like CSParser.namespace_body() 
          // Use reflection to find the rule to use.
          MethodInfo mi = p.GetType().GetMethod(startRule);

          if (mi == null)
          {
             throw new Exception("Could not find start rule " + startRule + " in csParser");
          }

          ParserRuleReturnScope csRet = (ParserRuleReturnScope) mi.Invoke(p, new object[0]);

          CommonTreeNodeStream csTreeStream = new CommonTreeNodeStream(csRet.Tree);
          csTreeStream.TokenStream = tokens;

          JavaMaker javaMaker = new JavaMaker(csTreeStream);
          javaMaker.TraceDestination = Console.Error;
          javaMaker.Cfg = Cfg;
          javaMaker.IsJavaish = true;

          // Try and call a rule like CSParser.namespace_body() 
          // Use reflection to find the rule to use.
          mi = javaMaker.GetType().GetMethod(startRule);

          if (mi == null)
          {
             throw new Exception("Could not find start rule " + startRule + " in javaMaker");
          }

          TreeRuleReturnScope javaSyntaxRet = (TreeRuleReturnScope) mi.Invoke(javaMaker, new object[0]);

          CommonTree javaSyntaxAST = (CommonTree)javaSyntaxRet.Tree;

//           CommonTreeNodeStream javaSyntaxNodes = new CommonTreeNodeStream(javaSyntaxAST);
// 
//           javaSyntaxNodes.TokenStream = csTree.TokenStream;
//                     
//           NetMaker netMaker = new NetMaker(javaSyntaxNodes);
//           netMaker.TraceDestination = Console.Error;
// 
//           netMaker.Cfg = Cfg;
//           netMaker.AppEnv = AppEnv;
//           
//           CommonTree javaAST = (CommonTree)netMaker.class_member_declarations().Tree;
//           
          return javaSyntaxAST;
       }

        // If true, then we are parsing some JavaIsh fragment
        private bool isJavaish = false;
	public bool IsJavaish 
	{
		get {
           return isJavaish;
        } 
        set {
           isJavaish = value;
        }
	}

       private Set<string> imports = new Set<string>();
       public Set<string> Imports 
       { 
          get
          {
             return imports;
          }
          set
          {
             imports = value;
          }
       }

       public virtual void AddToImports(string imp) {
          if (!String.IsNullOrEmpty(imp))
          {
             Imports.Add(imp);     
          }
       }

       public void AddToImports(IEnumerable<string> imps) {
          if (imps != null) {
             foreach (string imp in imps) {
                AddToImports(imp);
             }
          }
       }

    }

    // Wraps a compilation unit with its imports search path
    public class CUnit {

        public CUnit(CommonTree inTree, List<string> inSearchPath, List<string> inAliasKeys, List<string> inAliasValues) 
            : this(inTree, inSearchPath, inAliasKeys, inAliasValues, false)
        {
        }

       public CUnit(CommonTree inTree, List<string> inSearchPath, List<string> inAliasKeys, List<string> inAliasValues, bool inIsPartial) {
            Tree = inTree;
            SearchPath = inSearchPath;
            NameSpaceAliasKeys = inAliasKeys;
            NameSpaceAliasValues = inAliasValues;
            IsPartial = inIsPartial;
        }

        public CommonTree Tree {get; set;}

        // namespaces in scope
        public List<string> SearchPath {get; set;}

        //  aliases for namespaces
        public List<string> NameSpaceAliasKeys {get; set;}
        public List<string> NameSpaceAliasValues {get; set;}
        public bool IsPartial {get; set;}
    }

    public class ClassDescriptor {
       public IToken Token { get;set; }
       public String Comments { get;set; }
       public CommonTree Atts { get;set; }
       public CommonTree Mods { get;set; }
       public CommonTree Identifier { get;set; }
       public CommonTree TypeParameterList { get;set; }
       public CommonTree ClassBase { get;set; }
       public CommonTree TypeParameterConstraintsClauses { get;set; }
       public CommonTree ClassBody { get;set; }
       public Dictionary<String, ClassDescriptor> PartialTypes { get;set; }
       
       public ClassDescriptor(IToken inToken, String inComments, CommonTree inAtts, CommonTree inMods, CommonTree inIdentifier, CommonTree inTypeParameterList, CommonTree inClassBase, CommonTree inTypeParameterConstraintsClauses, CommonTree inClassBody, Dictionary<String, ClassDescriptor> inPartialTypes) {
          Token = inToken;
          Comments = inComments;
          Atts = inAtts;
          Mods = inMods;
          Identifier = inIdentifier;
          TypeParameterList = inTypeParameterList;
          ClassBase = inClassBase;
          TypeParameterConstraintsClauses = inTypeParameterConstraintsClauses;
          ClassBody = inClassBody;
          PartialTypes = inPartialTypes;
       }
    }

    public class ClassDescriptorSerialized {
       public String FileName { get;set; }
       public List<String> Imports { get;set; }
       public String Package { get;set; }
       public String Comments { get;set; }
       public String Atts { get;set; }
       public List<String> Mods { get;set; }
       public String Identifier { get;set; }
       public String TypeParameterList { get;set; }
       public String ClassBase { get;set; }
       public List<String> ClassImplements { get;set; }
       public String TypeParameterConstraintsClauses { get;set; }
       public String ClassBody { get;set; }
       
       public ClassDescriptorSerialized(string name)
       {
          FileName = "";
          Comments = "";
          Imports = new List<String>();
          Package = "";
          Atts = "";
          Mods = new List<String>();
          Identifier = name;
          TypeParameterList = "";
          ClassBase = "";
          ClassImplements = new List<String>();
          TypeParameterConstraintsClauses = "";
          ClassBody = "";
       }
    }

}
