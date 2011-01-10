using System;
using System.Collections;
using System.Collections.Generic;

namespace RusticiSoftware.Translator.Utils
{
    public class Set<T> : IEnumerable
    {

        /// 
        /// Provides the storage for elements in the Set, stored as the key-set
        /// of a Dictionary object.    
        /// 
        protected Dictionary<T, object> setD = null;
        private readonly static object PlaceholderObject = new object();

        public Set()
        {
            setD = new Dictionary<T,object>();
        }
        
        
        public IEnumerator GetEnumerator()
        {
            return setD.Keys.GetEnumerator();
        }     


        /// 
        /// The placeholder object used as the value for the Dictionary object.
        /// 
        /// There is a single instance of this object globally, used for all Sets.
        /// 
        protected object Placeholder
        {
            get { return PlaceholderObject; }
        }


        ///
        /// Adds the specified element to this set if it is not already present.
        /// o: The object to add to the set.
        /// returns true if the object was added, false if it was already present.
        public bool Add(T s)
        {
            if (setD.ContainsKey(s))
                return false;
            else
            {
                //The object we are adding is just a placeholder.  The thing we are
                //really concerned with is 'o', the key.
                setD[s] = PlaceholderObject;
                return true;
            }
        }

        ///
        /// Adds the specified element to this set if it is not already present.
        /// o: The object to add to the set.
        /// returns true if the object was added, false if it was already present.
        public void Add(IList<T> els)
        {
            if (els != null)
            {
                foreach (T s in els)
                {
                    Add(s);
                }
            }
        }

        public T[] AsArray()
        {
            ICollection keys = setD.Keys;
            T[] retArr = new T[keys.Count];

            keys.CopyTo(retArr, 0);

            return retArr;
        }
    }
}
