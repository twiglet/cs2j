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


    // Base Class for NetMaker phase, holds string literals that are spliced into
    // target classes to support Java interfaces such as Iterable etc.
    public class NetFragments : CommonWalker
    {

        protected NetFragments(ITreeNodeStream input, RecognizerSharedState state)
            : base(input, state)
        { }


       ////////////////////
       ///
       ///   Methods to convert Interfaces to Java equivalents
       ///
       ////////////////////

       // Takes a list of interface names e.g. [System.Collections.Generic.ICollection, System.IEnumerable]
       // and a list of type variables to substitute into fragments and returns a string containing the 
       // required methods
       // TypeVars in fragments have names T, T1, T2, T3, etc.
       public string getMethods(string iface, IList<string> tyArgs)
       {
          string ret = "";

          if (InterfaceMap.ContainsKey(iface))
          {
             string methods = InterfaceMap[iface];
             methods = rewriteCodeFragment(methods, tyArgs);
             ret += methods;
          }

          return ret;
       }


       private static Dictionary<string,string> interfaceMap = null;
       public static Dictionary<string,string> InterfaceMap
       {
          get
          {
             if (interfaceMap == null)
             {
                interfaceMap = new Dictionary<string,string>();
                interfaceMap["System.Collections.Generic.IEnumerable"] = genericIteratorMethodsStr;
                interfaceMap["System.Collections.Generic.ICollection"] = genericCollectorMethodsStr;
             }
             return interfaceMap;
          }
          
       }

       public static string GenericIteratorMethods(string T, string S)
       {
          return genericIteratorMethodsStr.Replace("${T}", T);
       }

       private static string genericIteratorMethodsStr = @"
    public   CS2J.java.util.Iterator<${T}> iterator() {
        CS2J.java.util.Iterator<${T}> ret = null;
        try
        {
            ret = CS2J.CS2JNet.JavaSupport.Collections.Generic.IteratorSupport.mk(this.@m{GetEnumerator}());
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }
        return ret;
    }
";

       public static string GenericCollectorMethods(string T, string S)
       {
          return genericCollectorMethodsStr.Replace("${T}", T).Replace("${T1}", S);
       }

       private static string genericCollectorMethodsStr = @"
	public boolean add(${T} el) {
        try
        {
            this.Add(el);
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }		
        return true;
	}

	public boolean addAll(Collection<? extends ${T}> c) {		
		for (${T} el : c) {
			this.add(el);
        }	
 		return true;
	}

	public void clear() {
        try
        {
            this.Clear();
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }			
	}

	public boolean contains(Object o) {
		boolean ret = false;
        try
        {
            ret = this.Contains((${T}) o);
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }		
 		return ret;
	}

	public boolean containsAll(Collection<?> c) {
		boolean ret = true;
		for (Object el : c) {
			if (!this.contains(el)) {
				ret = false;
				break;
        	}
        }		
 		return ret;
	}

	public boolean isEmpty() {
		return this.size() == 0;
	}

	public boolean remove(Object o) {
		boolean ret = false;
        try
        {
            ret = this.Remove((${T}) o);
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }		
 		return ret;
	}

	public boolean removeAll(Collection<?> c) {
		boolean ret = false;
		for (Object el : c) {
			ret = ret | this.remove(el);
		}
		return ret;
	}

	public boolean retainAll(Collection<?> c) {
		boolean ret = false;
		Object[] thisCopy = this.toArray();
		for (Object el : thisCopy) {
			if (!c.contains(el)) {
				ret = ret | this.remove(el);
			}
		}
		return ret;
	}

	public int size() {
		int ret = -1;
		try {
			return this.getCount();
		}
		catch (Exception e)
		{
			e.printStackTrace();
		}
		return ret;
	}


	public Object[] toArray() {
		Object[] ret = new Object[this.size()];
		int i = 0;
		for (Object el : this) {
			ret[i] = el;
                        i++;
		}
		return ret;
	}

	public T__S[] toArray<T__S>(T__S[] a) {
		System.Collections.Generic.IList<${T}> ret = new System.Collections.Generic.List<${T}>(this.size());
		for (${T} el : this) {
			ret.add(el);
		}
		return ret.toArray(a);
	}
";

    }
}
