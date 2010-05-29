using System;
using System.Collections;
using System.Text;

namespace RusticiSoftware.Translator
{

    // Implements a hierarchy of directories.
    public class DirectoryHT : IDictionary
    {

        private DirectoryHT _parent = null;

        private Hashtable leaves = new Hashtable();

        private Hashtable children = new Hashtable();

        public DirectoryHT(DirectoryHT p)
        {
            _parent = p;
        }

        public DirectoryHT()
            : this(null)
        { }


        public Hashtable Leaves
        {
            get { return leaves; }
        }

        // p is key to a sub directory
        public DirectoryHT subDir(string p)
        {
            string[] components = p.Split(new char[] { '.' }, 2);
            if (components.Length == 1)
            {
                return (DirectoryHT) children[components[0]];
            }
            else
            {
                DirectoryHT child = (DirectoryHT)children[components[0]];
                return (child == null ? null : child.subDir(components[1]));
            }
        }

        #region IDictionary Members

        public void Add(object key, object value)
        {
            if (!(key is string))
               throw new Exception("The method or operation is not implemented.");
            
            string[] components = ((string)key).Split(new char[] { '.' }, 2);
            if (components.Length == 1)
            {
                leaves[components[0]] = value;
            }
            else
            {
                if (children[components[0]] == null)
                    children[components[0]] = new DirectoryHT(this);
                ((DirectoryHT)children[components[0]]).Add(components[1], value);
            }
        }

        public void Clear()
        {
            leaves.Clear();
            children.Clear();
        }

        public bool Contains(object key)
        {
            if (!(key is string)) 
                throw new Exception("The method or operation is not implemented.");
            string[] components = ((String)key).Split(new char[] { '.' }, 2);
            if (components.Length == 1)
            {
                return leaves.Contains(components[0]);
            }
            else
            {
                return ((DirectoryHT)children[components[0]]).Contains(components[1]);
            }
        }

        public IDictionaryEnumerator GetEnumerator()
        {
            IDictionaryEnumerator[] des = new IDictionaryEnumerator[1 + children.Count];
            string[] pres = new string[1 + children.Count];
            int i = 1;

            pres[0] = "";
            des[0] = leaves.GetEnumerator();
            foreach (DictionaryEntry de in children)
            {
                pres[i] = ((string)de.Key) + ".";
                des[i] = ((DirectoryHT)de.Value).GetEnumerator();
                i++;
            }

            return new DirectoryHTEnumerator(pres,des); 
        }

        public bool IsFixedSize
        {
            get { return false; }
        }

        public bool IsReadOnly
        {
            get { return false; }
        }

        public ICollection Keys
        {
            get {
                ArrayList keys = new ArrayList();
                foreach (object k in leaves.Keys)
                    keys.Add(k);
                foreach (DictionaryEntry de in children)
                    foreach (string k in ((DirectoryHT)de.Value).Keys)
                        keys.Add(de.Key + "." + k);
                return keys;
            }
        }

        public void Remove(object key)
        {
             if (!(key is string)) 
                throw new Exception("The method or operation is not implemented.");
            string[] components = ((string)key).Split(new char[] { '.' }, 2);
            if (components.Length == 1)
            {
                leaves.Remove(components[0]);
            }
            else
            {
                ((DirectoryHT)children[components[0]]).Remove(components[1]);
            }
        }

        public ICollection Values
        {
 
            get {
                ArrayList vals = new ArrayList();
                foreach (object v in leaves.Values)
                    vals.Add(v);
                foreach (DictionaryEntry de in children)
                    foreach (object v in ((DirectoryHT)de.Value).Values)
                        vals.Add(v);
                return vals;
            }
        }

        public object this[object key]
        {
            get
            {
                if (!(key is string))
                    throw new Exception("The method or operation is not implemented.");
                string[] components = ((string)key).Split(new char[] { '.' }, 2);
                if (components.Length == 1)
                {
                    object val = leaves[components[0]];
                    return (val != null ? val : children[components[0]]);
                }
                else
                {
                    DirectoryHT child = (DirectoryHT)children[components[0]];
                    return (child == null ? null : child[components[1]]);
                }
            }
            set
            {
                Add(key, value);
            }
        }

        #endregion

        #region ICollection Members

        public void CopyTo(Array array, int index)
        {
            throw new Exception("The method or operation is not implemented.");
        }

        public int Count
        {
            get
            {
                int count = leaves.Count;
                foreach (DirectoryHT c in children.Values)
                    count += c.Count;
                return count;
            }
        }

        public bool IsSynchronized
        {
            get { throw new Exception("The method or operation is not implemented."); }
        }

        public object SyncRoot
        {
            get { throw new Exception("The method or operation is not implemented."); }
        }

        #endregion

        #region IEnumerable Members

        IEnumerator IEnumerable.GetEnumerator()
        {
            return GetEnumerator();
        }

        #endregion
    }

    public class DirectoryHTEnumerator : IDictionaryEnumerator
    {
        private int _pos = 0;
        private string[] _prefixes;
        private IDictionaryEnumerator[] _enums;

        public DirectoryHTEnumerator(string[] pres, IDictionaryEnumerator[] des)
        {
            _prefixes = pres;
            _enums = des;
        }

        #region IDictionaryEnumerator Members

        public DictionaryEntry Entry
        {
            get { return (DictionaryEntry)Current; }
        }

        public object Key
        {
            get { return Entry.Key; }
        }

        public object Value
        {
            get { return Entry.Value; }
        }

        #endregion

        #region IEnumerator Members

        public object Current
        {
            get { ValidateIndex(); 
                  return new DictionaryEntry(_prefixes[_pos] + (string)((DictionaryEntry)_enums[_pos].Current).Key, 
                                             ((DictionaryEntry)_enums[_pos].Current).Value); 
            }
        }

        public bool MoveNext()
        {
            if (_pos >= _enums.Length)
                return false;

            while (_pos < _enums.Length && !_enums[_pos].MoveNext())
                _pos++;

            return _pos != _enums.Length;
        }

        public void Reset()
        {
            _pos = 0;
        }

        // Validate the enumeration index and throw an exception if the index is out of range.
        private void ValidateIndex()
        {
            if (_pos < 0 || _pos >= _enums.Length)
                throw new InvalidOperationException("Enumerator is before or after the collection.");
        }

        #endregion
    }
}
