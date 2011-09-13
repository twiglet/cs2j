using System;
using System.Collections;

namespace Nini.Util
{
	//[Serializable]
	/// <include file='OrderedList.xml' path='//Class[@name="OrderedList"]/docs/*' />
	public class OrderedList : ICollection, IDictionary, IEnumerable
	{
		#region Private variables
		Hashtable table = new Hashtable ();
		ArrayList list = new ArrayList ();
		#endregion

		#region Public properties
		/// <include file='OrderedList.xml' path='//Property[@name="Count"]/docs/*' />
		public int Count 
		{
			get { return list.Count; }
		}

		/// <include file='OrderedList.xml' path='//Property[@name="IsFixedSize"]/docs/*' />
		public bool IsFixedSize 
		{
			get { return false; }
		}

		/// <include file='OrderedList.xml' path='//Property[@name="IsReadOnly"]/docs/*' />
		public bool IsReadOnly 
		{
			get { return false; }
		}

		/// <include file='OrderedList.xml' path='//Property[@name="IsSynchronized"]/docs/*' />
		public bool IsSynchronized 
		{
			get { return false; }
		}

		/// <include file='OrderedList.xml' path='//Property[@name="ItemIndex"]/docs/*' />
		public object this[int index] 
		{
			get { return ((DictionaryEntry) list[index]).Value; }
			set 
			{
				if (index < 0 || index >= Count)
					throw new ArgumentOutOfRangeException ("index");

				object key = ((DictionaryEntry) list[index]).Key;
				list[index] = new DictionaryEntry (key, value);
				table[key] = value;
			}
		}

		/// <include file='OrderedList.xml' path='//Property[@name="ItemKey"]/docs/*' />
		public object this[object key] 
		{
			get { return table[key]; }
			set 
			{
				if (table.Contains (key))
				{
					table[key] = value;
					table[IndexOf (key)] = new DictionaryEntry (key, value);
					return;
				}
				Add (key, value);
			}
		}

		/// <include file='OrderedList.xml' path='//Property[@name="Keys"]/docs/*' />
		public ICollection Keys 
		{
			get 
			{ 
				ArrayList retList = new ArrayList ();
				for (int i = 0; i < list.Count; i++)
				{
					retList.Add ( ((DictionaryEntry)list[i]).Key );
				}
				return retList;
			}
		}

		/// <include file='OrderedList.xml' path='//Property[@name="Values"]/docs/*' />
		public ICollection Values 
		{
			get 
			{
				ArrayList retList = new ArrayList ();
				for (int i = 0; i < list.Count; i++)
				{
					retList.Add ( ((DictionaryEntry)list[i]).Value );
				}
				return retList;
			}
		}

		/// <include file='OrderedList.xml' path='//Property[@name="SyncRoot"]/docs/*' />
		public object SyncRoot 
		{
			get { return this; }
		}
		#endregion

		#region Public methods
		/// <include file='OrderedList.xml' path='//Method[@name="Add"]/docs/*' />
		public void Add (object key, object value)
		{
			table.Add (key, value);
			list.Add (new DictionaryEntry (key, value));
		}

		/// <include file='OrderedList.xml' path='//Method[@name="Clear"]/docs/*' />
		public void Clear ()
		{
			table.Clear ();
			list.Clear ();
		}

		/// <include file='OrderedList.xml' path='//Method[@name="Contains"]/docs/*' />
		public bool Contains (object key)
		{
			return table.Contains (key);
		}

		/// <include file='OrderedList.xml' path='//Method[@name="CopyTo"]/docs/*' />
		public void CopyTo (Array array, int index)
		{
			table.CopyTo (array, index);
		}
		
		/// <include file='OrderedList.xml' path='//Method[@name="CopyToStrong"]/docs/*' />
		public void CopyTo (DictionaryEntry[] array, int index)
		{
			table.CopyTo (array, index);
		}

		/// <include file='OrderedList.xml' path='//Method[@name="Insert"]/docs/*' />
		public void Insert (int index, object key, object value)
		{
			if (index > Count)
				throw new ArgumentOutOfRangeException ("index");

			table.Add (key, value);
			list.Insert (index, new DictionaryEntry (key, value));
		}

		/// <include file='OrderedList.xml' path='//Method[@name="Remove"]/docs/*' />
		public void Remove (object key)
		{
			table.Remove (key);
			list.RemoveAt (IndexOf (key));
		}

		/// <include file='OrderedList.xml' path='//Method[@name="RemoveAt"]/docs/*' />
		public void RemoveAt (int index)
		{
			if (index >= Count)
				throw new ArgumentOutOfRangeException ("index");

			table.Remove ( ((DictionaryEntry)list[index]).Key );
			list.RemoveAt (index);
		}

		/// <include file='OrderedList.xml' path='//Method[@name="GetEnumerator"]/docs/*' />
		public IEnumerator GetEnumerator () 
		{
			return new OrderedListEnumerator (list);
		}

		/// <include file='OrderedList.xml' path='//Method[@name="GetDictionaryEnumerator"]/docs/*' />
		IDictionaryEnumerator IDictionary.GetEnumerator ()
		{
			return new OrderedListEnumerator (list);
		}

		/// <include file='OrderedList.xml' path='//Method[@name="GetIEnumerator"]/docs/*' />
		IEnumerator IEnumerable.GetEnumerator ()
		{
			return new OrderedListEnumerator (list);
		}
		#endregion

		#region Private variables
		private int IndexOf (object key)
		{
			for (int i = 0; i < list.Count; i++)
			{
				if (((DictionaryEntry) list[i]).Key.Equals (key))
				{
					return i;
				}
			}
			return -1;
		}
		#endregion
	}
}
