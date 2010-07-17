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
        protected CommonWalker(ITreeNodeStream input, RecognizerSharedState state)
            : base(input, state)
        { }
        

        protected void Debug(String s)
        {
            Console.Out.WriteLine(s);
        }
    }
}
