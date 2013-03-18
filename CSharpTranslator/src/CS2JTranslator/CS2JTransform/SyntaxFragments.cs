/*
   Copyright 2010-2013 Kevin Glynn (kevin.glynn@twigletsoftware.com)
   Copyright 2007-2013 Rustici Software, LLC

This program is free software: you can redistribute it and/or modify
it under the terms of the MIT/X Window System License

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

You should have received a copy of the MIT/X Window System License
along with this program.  If not, see 

   <http://www.opensource.org/licenses/mit-license>
*/

using System;
using System.Collections.Generic;
using Antlr.Runtime.Tree;
using Antlr.Runtime;

namespace Twiglet.CS2J.Translator.Transform
{


    // Base Class for JavaMaker phase, holds string literals that are spliced into
    // target classes to support Delegates
    public class SyntaxFragments : CommonWalker
    {


        protected SyntaxFragments(ITreeNodeStream input, RecognizerSharedState state)
            : base(input, state)
        { }


       ////////////////////
       ///
       ///   Delegates
       ///
       ////////////////////
       public string DelegateObject(String delName, String args, String body)
       {
          return delegateObject.Replace("${D}",delName).Replace("${A}",args).Replace("${B}",body);
       }

       private static string delegateObject = @"
          new ${D}() { public void Invoke(${A}) { ${B}; } }
";

       public string MultiDelegateMethods(string Del, string DelClass, string TyArgs)
       {
          return rewriteCodeFragment(multiDelegateMethodsStr.Replace("${Del}", Del).Replace("${DelClass}", DelClass).Replace("${TyArgs}", TyArgs), new List<string>());
       }

       private string multiDelegateMethodsStr = @"
    	private System.Collections.Generic.IList<${Del}> _invocationList = new ArrayList<${Del}>();
    	
    	public static ${Del} Combine ${TyArgs} (${Del} a, ${Del} b) throws Exception {
            if (a == null) return b;
            if (b == null) return a;
    	    ${DelClass} ret = new ${DelClass}();
    	    ret._invocationList = a.@m{GetInvocationList}();
    	    ret._invocationList.addAll(b.@m{GetInvocationList}());
    	    return ret;
    	}
    	
        public static ${Del} Remove ${TyArgs} (${Del} a, ${Del} b) throws Exception {
            if (a == null || b == null) return a;
	    System.Collections.Generic.IList<${Del}> aInvList = a.@m{GetInvocationList}();
	    System.Collections.Generic.IList<${Del}> newInvList = ListSupport.removeFinalStretch(aInvList, b.@m{GetInvocationList}());
	    if (aInvList == newInvList) {
	        return a;
	    }
	    else {
	        ${DelClass} ret = new ${DelClass}();
	        ret._invocationList = newInvList;
	        return ret;
	    }
	}

    	public System.Collections.Generic.IList<${Del}> GetInvocationList() throws Exception {
    	    return _invocationList;
    	}
";

    }
}
