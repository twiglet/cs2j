using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Antlr.Runtime.Tree;
using Antlr.Runtime;

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

    }

    // Wraps a compilation unit with its imports search path
    public class CUnit {

        public CUnit(CommonTree inTree, List<string> inSearchPath, List<string> inAliasKeys, List<string> inAliasValues) {
            Tree = inTree;
            SearchPath = inSearchPath;
            NameSpaceAliasKeys = inAliasKeys;
            NameSpaceAliasValues = inAliasValues;
        }
        public CommonTree Tree {get; set;}

        // namespaces in scope
        public List<string> SearchPath {get; set;}

        //  aliases for namespaces
        public List<string> NameSpaceAliasKeys {get; set;}
        public List<string> NameSpaceAliasValues {get; set;}
    }

}
