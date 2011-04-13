/*
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

using System;
using System.Collections.Generic;
using Antlr.Runtime.Tree;

namespace Twiglet.CS2J.Translator
{
    public class Fragments
    {

       public static string GenericCollectorMethods(string T, string S)
       {
          return genericCollectorMethodsStr.Replace("${T}", T).Replace("${S}", S);
       }

       private static string genericCollectorMethodsStr = @"
    public   Iterator<${T}> iterator() {
        Iterator<${T}> ret = null;
        try
        {
            ret = this.GetEnumerator().iterator();
        }
        catch (Exception e)
        {
            e.printStackTrace();
        }
        return ret;
    }

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
		return false;
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
		}
		return ret;
	}

        // NOTE: Moved <S> to after the method name, like C# not Java, to help the poor parser.
	public ${S}[] toArray<${S}>(${S}[] a) {
		ArrayList<${T}> ret = new ArrayList<${T}>(this.size());
		for (${T} el : this) {
			ret.add(el);
		}
		return ret.toArray(a);
	}
";

       public static string GenIterator = @"    
            public   Iterator<${T}> iterator() {
                Iterator<${T}> ret = null;
                try
                {
                    ret = this.GetEnumerator().iterator();
                }
                catch (Exception e)
                {
                    e.printStackTrace();
                }
                return ret;
            }";

       private static Dictionary<string, CommonTree> _fragmentsLibrary = null;
       public static Dictionary<string, CommonTree> FragmentsLibrary 
       { get
           { 
              if (_fragmentsLibrary == null)
              {
                 _fragmentsLibrary = new Dictionary<string, CommonTree>();
              }
              return _fragmentsLibrary;
           }
       }
    }
}
