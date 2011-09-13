using System;
using System.Collections;

namespace Nini.Util
{
	/// <include file='OrderedListEnumerator.xml' path='//Class[@name="OrderedListEnumerator"]/docs/*' />
	public class OrderedListEnumerator : IDictionaryEnumerator
	{
		#region Private variables
		int index = -1;
		ArrayList list;
		#endregion

		#region Constructors
		/// <summary>
		/// Instantiates an ordered list enumerator with an ArrayList.
		/// </summary>
		internal OrderedListEnumerator (ArrayList arrayList)
		{
			list = arrayList;
		}
		#endregion

		#region Public properties
		/// <include file='OrderedListEnumerator.xml' path='//Property[@name="Current"]/docs/*' />
		object IEnumerator.Current 
		{
			get 
			{
				if (index < 0 || index >= list.Count)
					throw new InvalidOperationException ();

				return list[index];
			}
		}
		
		/// <include file='OrderedListEnumerator.xml' path='//Property[@name="CurrentStrong"]/docs/*' />
		public DictionaryEntry Current 
		{
			get 
			{
				if (index < 0 || index >= list.Count)
					throw new InvalidOperationException ();

				return (DictionaryEntry)list[index];
			}
		}

		/// <include file='OrderedListEnumerator.xml' path='//Property[@name="Entry"]/docs/*' />
		public DictionaryEntry Entry 
		{
			get { return (DictionaryEntry) Current; }
		}

		/// <include file='OrderedListEnumerator.xml' path='//Property[@name="Key"]/docs/*' />
		public object Key 
		{
			get { return Entry.Key; }
		}

		/// <include file='OrderedListEnumerator.xml' path='//Property[@name="Value"]/docs/*' />
		public object Value 
		{
			get { return Entry.Value; }
		}
		#endregion

		#region Public methods
		/// <include file='OrderedListEnumerator.xml' path='//Method[@name="MoveNext"]/docs/*' />
		public bool MoveNext ()
		{
			index++;
			if (index >= list.Count)
				return false;

			return true;
		}

		/// <include file='OrderedListEnumerator.xml' path='//Method[@name="Reset"]/docs/*' />
		public void Reset ()
		{
			index = -1;
		}
		#endregion
	}
}