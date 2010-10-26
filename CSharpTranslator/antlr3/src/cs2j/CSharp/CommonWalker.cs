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
		protected CS2JSettings Cfg { get; set; }

        protected CommonWalker(ITreeNodeStream input, RecognizerSharedState state)
            : base(input, state)
        { }

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
    }
}
