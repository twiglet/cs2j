using System;
using System.Collections;
using System.Text;


namespace RusticiSoftware.Translator
{
    // Holds our symbol table, a multi-level map from identifiers (string) to their type (string)

    public class SymbolTable
    {
        // A stack of hashtables
        private Stack _outer = null;
       

        public SymbolTable()
        {
            _outer = new Stack();
            PushLevel();
        }

        public void PushLevel()
        {
            _outer.Push(new Hashtable());
        }

        public void PopLevel()
        {
            _outer.Pop();
        }

        // keving: Can we try to add the same var twice??
        public void Add(string v, TypeRep t)
        {
            ((Hashtable)_outer.Peek())[v] = t;
        }

        public TypeRep Get(string v)
        {
            //TypeRep unknownType;

            foreach (Hashtable d in _outer)
            {
                if (d.Contains(v))
                    return (TypeRep) d[v];
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

        public void Dump()
        {
            string INDENT = "";
            Console.WriteLine("symbol Table Dump");

            foreach (Hashtable d in _outer)
            {
                foreach (string v in d.Keys)
                {
                    Console.WriteLine(INDENT + v + ": " + ((TypeRep)d[v]).TypeName);
                }
                INDENT += "    ";
            }
            Console.WriteLine("");
        }

    }

}
