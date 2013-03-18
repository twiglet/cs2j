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
using System.Text;
using System.Collections.Generic;


/*
  DirectoryHT is a dictionary, designed to model C#'s class name space.  

  Keys are dot separated strings (e.g. System.IO.TextWriter).  The value stored has
  a parameterized type (in CS2J we are storing TypeRepTemplates).

  Each Key can point to a list of possible values, indexed by variant.

  Valid variants are stored in the Alts property. The Alts are ordered by priority,
  lowest to highest.  We return the value with highest priority variant.  

  There is a default variant (with variant specified by the Default property). This is
  always valid and has lowest ptiority.

  Default Default (ahem!) is the empty string.

 */


namespace Twiglet.CS2J.Translator.Utils
{

    // Implements a hierarchy of directories.
    public class DirectoryHT<TValue> : IDictionary<string, TValue>
    {

        private DirectoryHT<TValue> parent = null;

        // Leaves are a dictionary from Variant to Entry
        private Dictionary<string, Dictionary<string, TValue>> leaves = new Dictionary<string, Dictionary<string, TValue>>();

        // Children point to sub directories.
        private Dictionary<string, DirectoryHT<TValue>> children = new Dictionary<string, DirectoryHT<TValue>>();

        // The enabled Variants, in priority order.
        private IList<string> alts = new List<string>();

        // Default Variant (always enabled)
        private string _default = String.Empty;

        public DirectoryHT(DirectoryHT<TValue> p)
        {
            parent = p;
            if (p != null)
            {
               Default = p.Default;
               Alts = p.Alts;
            }
        }

        public DirectoryHT()
            : this(null)
        { }


        public Dictionary<string, Dictionary<string, TValue>> Leaves
        {
            get { return leaves; }
        }

        // p is key to a sub directory
        public DirectoryHT<TValue> Parent
        {  
            get { return parent; }
        }

        // When looking for A.B.C.D.E We get a dictionary of variants. We will first look for each
        // variant in Alts before falling back on the default (variant = Default)
        // This allows to override the default translations where necessary
        // Alts appearing later in the list have priority. 
        public IList<string> Alts
        {  
            get { return alts; }
            set
            {
               alts = value;
               foreach (KeyValuePair<string, DirectoryHT<TValue>> child in children)
                  child.Value.Alts = value;
            }
        }

        public string Default
        {
           get
           {
              return _default;
           }
           set
           {
              _default = value;
              foreach (KeyValuePair<string,DirectoryHT<TValue>> child in children)
                 child.Value.Default = value;
           }
        }

        // p is key to a sub directory
        public DirectoryHT<TValue> subDir(string p)
        {
            string[] components = p.Split(new char[] { '.' }, 2);
            if (components.Length == 1)
            {
                return children[components[0]];
            }
            else
            {
                DirectoryHT<TValue> child = children[components[0]];
                return (child == null ? null : child.subDir(components[1]));
            }
        }

        private bool hasLeaf(Dictionary<string,TValue> variants)
        {
           if (variants == null)
              return false;
           if (variants.ContainsKey(Default))
              return true;
           foreach (string alt in Alts)
           {
              if (variants.ContainsKey(alt))
                  return true;
           }
           return false;
        }

        private TValue getLeaf(Dictionary<string,TValue> variants)
        {
           return getLeaf(variants, default(TValue));
        }

        private TValue getLeaf(Dictionary<string,TValue> variants, TValue def)
        {
           if (variants == null)
              return def;
           for (int i = Alts.Count - 1; i >= 0; i--)
           {
              if (variants.ContainsKey(Alts[i]))
                  return variants[Alts[i]];
           }
           if (variants.ContainsKey(Default))
              return variants[Default];
           return def;
        }

        #region IDictionary Members



        public bool ContainsKey(string key)
        {
            string[] components = key.Split(new char[] { '.' }, 2);
            if (components.Length == 1)
            {
               return leaves.ContainsKey(components[0]) ? hasLeaf(leaves[components[0]]) : false; 
            }
            else
            {
                if (children.ContainsKey(components[0]))
                {
                    return children[components[0]].ContainsKey(components[1]);
                }
                else
                {
                    return false;        
                }
            }
        }

        //        public IDictionaryEnumerator GetEnumerator()
        //        {
        //            IDictionaryEnumerator[] des = new IDictionaryEnumerator[1 + children.Count];
        //            string[] pres = new string[1 + children.Count];
        //            int i = 1;
        //
        //            pres[0] = "";
        //            des[0] = leaves.GetEnumerator();
        //            foreach (DictionaryEntry de in children)
        //            {
        //                pres[i] = ((string)de.Key) + ".";
        //                des[i] = ((DirectoryHT)de.Value).GetEnumerator();
        //                i++;
        //            }
        //
        //            return new DirectoryHTEnumerator(pres,des); 
        //        }

        public ICollection<string> Keys
        {
            get
            {
                List<string> keys = new List<string>();
                foreach (string k in leaves.Keys)
                {
                   if (hasLeaf(leaves[k]))
                      keys.Add(k);
                }
                foreach (KeyValuePair<string, DirectoryHT<TValue>> de in children)
                    foreach (string k in de.Value.Keys)
                        keys.Add(de.Key + "." + k);
                return keys;
            }
        }

        public bool Remove(string key)
        {
            string[] components = ((string)key).Split(new char[] { '.' }, 2);
            if (components.Length == 1)
            {
                return leaves.Remove(components[0]);
            }
            else
            {
               if (children.ContainsKey(components[0]))
               {
                  return children[components[0]].Remove(components[1]);
               }
               else
               {
                  return false;
               }
            }
        }

        public ICollection<TValue> Values
        {

            get
            {
                List<TValue> vals = new List<TValue>();
                foreach (Dictionary<string,TValue> variants in leaves.Values)
                {
                   if (hasLeaf(variants))
                   {
                      vals.Add(getLeaf(variants));
                   }
                }
                foreach (KeyValuePair<string, DirectoryHT<TValue>> de in children)
                    foreach (TValue v in de.Value.Values)
                        vals.Add(v);
                return vals;
            }
        }

        public TValue this[string key]
        {
            get
            {
                // will throw KeyNotFound exception if not present
                string[] components = key.Split(new char[] { '.' }, 2);
                if (components.Length == 1)
                {
                   if (leaves.ContainsKey(key) && hasLeaf(leaves[key]))
                   {
                      return getLeaf(leaves[key]); 
                   }
                   else
                   {
                      throw new KeyNotFoundException(key);
                   }
                }
                else
                {
                    DirectoryHT<TValue> child = children[components[0]];
                    return child[components[1]];
                }
            }
            set
            {
                Add(key, value);
            }
        }

        public bool TryGetValue(string key, out TValue value)
        {
            string[] components = key.Split(new char[] { '.' }, 2);
            if (components.Length == 1)
            {
               if (leaves.ContainsKey(components[0]) && hasLeaf(leaves[components[0]]))
               {
                  value = getLeaf(leaves[components[0]]);
                  return true;
               }
            }
            else
            {
               if (children.ContainsKey(components[0]))
                {
                   return children[components[0]].TryGetValue(components[1], out value);
                }
            }
            value = default(TValue);
            return false;
        }

        // search for name, given searchPath
        // searchPath is searched in reverse order

        // When searching for A.B.C.D.E we will first search for each A.B.C.D.<alt>.E where <alt> comes from Alts
        // This allows to override the default translations where necessary
        public TValue Search(IList<string> searchPath, string name, TValue def) {
            
           bool doneGlobal = false;
            // First check against each element of the search path 
            if (searchPath != null)
            {
               for (int i = searchPath.Count-1; i >= 0; i--) {
                  String ns = searchPath[i];
                  if (String.IsNullOrEmpty(ns))
                     doneGlobal = true;
                  String fullName = (ns ?? "") + (String.IsNullOrEmpty(ns) ? "" : ".") + name;
                  if (this.ContainsKey(fullName)) {
                     return this[fullName];
                  }
               }
            }
            // Not in search path, check for fully qualified name
            if (!doneGlobal)
            {
               if (this.ContainsKey(name)) {
                  return this[name];
               }
            }
            // Not found *anywhere*!
            return def;
        }

        // search for name, given searchPath
        // searchPath is searched in reverse order
        public TValue Search(IList<string> searchPath, string name) {
            return Search(searchPath, name, default(TValue));
        }

        public TValue Search(string name) {
            return Search(new List<string>(), name);
        }

        public TValue Search(string name, TValue def) {
            return Search(new List<string>(), name, def);
        }

        public bool Contains(KeyValuePair<string, TValue> item)
        {
            TValue value;
            if (!this.TryGetValue(item.Key, out value))
                return false;

            return EqualityComparer<TValue>.Default.Equals(value, item.Value);
        }

        public bool Remove(KeyValuePair<string, TValue> item)
        {
            if (!this.Contains(item))
                return false;

            return this.Remove(item.Key);
        }

        public void CopyTo(KeyValuePair<string, TValue>[] array, int arrayIndex)
        {
            Copy(this, array, arrayIndex);
        }

        public void Add(KeyValuePair<string, TValue> item)
        {
           Add(item.Key, item.Value);
        }

        public void Add(string key, TValue value)
        {
           Add(key, value, Default);
        }

        public void Add(string key, TValue value, string variant)
        {
            string[] components = key.Split(new char[] { '.' }, 2);
            if (components.Length == 1)
            {
               if (!leaves.ContainsKey(components[0]))
               {
                  leaves[components[0]] = new Dictionary<string, TValue>();
               }
               leaves[components[0]][variant] = value;
            }
            else
            {
                if (!children.ContainsKey(components[0]))
                    children[components[0]] = new DirectoryHT<TValue>(this);
                children[components[0]].Add(components[1], value, variant);
            }
        }

        public IEnumerator<KeyValuePair<string, TValue>> GetEnumerator()
        {
            foreach (KeyValuePair<string, DirectoryHT<TValue>> de in children)
            {
                foreach (KeyValuePair<string, TValue> cur in de.Value)
                {
                    yield return new KeyValuePair<string, TValue>(de.Key + "." + cur.Key, cur.Value);
                }
            }
            foreach (KeyValuePair<string, Dictionary<string, TValue>> de in leaves)
            {
               if (hasLeaf(de.Value))
               {
                  yield return new KeyValuePair<string, TValue>(de.Key, getLeaf(de.Value));
               }
            }
        }

        System.Collections.IEnumerator System.Collections.IEnumerable.GetEnumerator()
        {
            return this.GetEnumerator();
        }

        #endregion

        #region ICollection Members

        public int Count
        {
            get
            {
                int count = leaves.Count;
                foreach (DirectoryHT<TValue> c in children.Values)
                    count += c.Count;
                return count;
            }
        }

        public bool IsReadOnly
        {
            get { return false; }
        }

        public void Clear()
        {
            leaves.Clear();
            children.Clear();
        }

        #endregion


        private static void Copy<T>(ICollection<T> source, T[] array, int arrayIndex)
        {
            if (array == null)
                throw new ArgumentNullException("array");

            if (arrayIndex < 0 || arrayIndex > array.Length)
                throw new ArgumentOutOfRangeException("arrayIndex");

            if ((array.Length - arrayIndex) < source.Count)
                throw new ArgumentException("Destination array is not large enough. Check array.Length and arrayIndex.");

            foreach (T item in source)
                array[arrayIndex++] = item;
        }
    }
}
