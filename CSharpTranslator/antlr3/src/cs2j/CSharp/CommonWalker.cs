using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Antlr.Runtime.Tree;
using Antlr.Runtime;

namespace RusticiSoftware.Translator.CSharp
{
    public class CommonWalker : TreeParser
    {
		public CS2JSettings Cfg { get; set; }
		public string Filename { get; set; }

        protected CommonWalker(ITreeNodeStream input, RecognizerSharedState state)
            : base(input, state)
        { }

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
        protected string mkTypeName (string name, List<String> tyargs) {
            return name + (tyargs.Count > 0 ? "'" + tyargs.Count.ToString() : "");
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
    }
}
