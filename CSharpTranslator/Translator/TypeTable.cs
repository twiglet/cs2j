using System;
using System.Collections;
using System.Text;
using System.IO;
using System.Xml.Serialization;

namespace RusticiSoftware.Translator
{
    // Holds our symbol table, a multi-level map from identifiers (string) to their type (string)

    public class TypeTable
    {
        private Stack _outer = new Stack();
        // _global always points to the bottom of the stack where global types live
        private Hashtable _global = null;

        public TypeTable()
        {
            // _global always points to the bottom of the stack where global types live
            PushLevel();
            _global = (Hashtable) _outer.Peek();
        }

        public void PushLevel()
        {
            _outer.Push(new Hashtable());
        }

        public void PopLevel()
        {
            _outer.Pop();
        }

        
        public void Add(string typeName, TypeRep t)
        {
            ((Hashtable)_outer.Peek())[typeName] = t;
        }

        public TypeRep Get(string typeName)
        {
            foreach (Hashtable d in _outer)
            {
                if (d.Contains(typeName))
                    return (TypeRep)d[typeName];
            }
            return null;
        }

        public TypeRep this[string v]
        {
            get
            {
                return Get(v);
            }
            set
            {
                Add(v, value);
            }
        }


        override public string ToString()
        {
            return _outer.ToString();
        }
    }

}
