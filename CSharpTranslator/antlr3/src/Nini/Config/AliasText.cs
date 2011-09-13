#region Copyright
//
// Nini Configuration Project.
// Copyright (C) 2006 Brent R. Matzelle.  All rights reserved.
//
// This software is published under the terms of the MIT X11 license, a copy of 
// which has been included with this distribution in the LICENSE.txt file.
// 
#endregion

using System;
using System.Collections;

namespace Nini.Config
{
	/// <include file='AliasText.xml' path='//Class[@name="AliasText"]/docs/*' />
	public class AliasText
	{
		#region Private variables
		Hashtable intAlias = null;
		Hashtable booleanAlias = null;
		#endregion

		#region Constructors
		/// <include file='AliasText.xml' path='//Constructor[@name="AliasText"]/docs/*' />
		public AliasText ()
		{
			intAlias = InsensitiveHashtable ();
			booleanAlias = InsensitiveHashtable ();
			DefaultAliasLoad ();
		}
		#endregion
		
		#region Public methods
		/// <include file='AliasText.xml' path='//Method[@name="AddAliasInt"]/docs/*' />
		public void AddAlias (string key, string alias, int value)
		{
			if (intAlias.Contains (key)) {
				Hashtable keys = (Hashtable)intAlias[key];
				
				keys[alias] = value;
			} else {
				Hashtable keys = InsensitiveHashtable ();
				keys[alias] = value;
				intAlias.Add (key, keys);
			}
		}
		
		/// <include file='AliasText.xml' path='//Method[@name="AddAliasBoolean"]/docs/*' />
		public void AddAlias (string alias, bool value)
		{
			booleanAlias[alias] = value;
		}
		
#if (NET_COMPACT_1_0)
#else
		/// <include file='AliasText.xml' path='//Method[@name="AddAliasEnum"]/docs/*' />
		public void AddAlias (string key, Enum enumAlias)
		{
			SetAliasTypes (key, enumAlias);
		}
#endif
		
		/// <include file='AliasText.xml' path='//Method[@name="ContainsBoolean"]/docs/*' />
		public bool ContainsBoolean (string key)
		{
			return booleanAlias.Contains (key);
		}
		
		/// <include file='AliasText.xml' path='//Method[@name="ContainsInt"]/docs/*' />
		public bool ContainsInt (string key, string alias)
		{
			bool result = false;

			if (intAlias.Contains (key)) {
				Hashtable keys = (Hashtable)intAlias[key];
				result = (keys.Contains (alias));
			}
			
			return result;
		}
		
		/// <include file='AliasText.xml' path='//Method[@name="GetBoolean"]/docs/*' />
		public bool GetBoolean (string key)
		{
			if (!booleanAlias.Contains (key)) {
				throw new ArgumentException ("Alias does not exist for text");
			}
			
			return (bool)booleanAlias[key];
		}
		
		/// <include file='AliasText.xml' path='//Method[@name="GetInt"]/docs/*' />
		public int GetInt (string key, string alias)
		{
			if (!intAlias.Contains (key)) {
				throw new ArgumentException ("Alias does not exist for key");
			}

			Hashtable keys = (Hashtable)intAlias[key];

			if (!keys.Contains (alias)) {
				throw new ArgumentException ("Config value does not match a " +
											 "supplied alias");
			}
			
			return (int)keys[alias];
		}
		#endregion
		
		#region Private methods
		/// <summary>
		/// Loads the default alias values.
		/// </summary>
		private void DefaultAliasLoad ()
		{
			AddAlias("true", true);
			AddAlias("false", false);
		}

#if (NET_COMPACT_1_0)
#else
		/// <summary>
		/// Extracts and sets the alias types from an enumeration.
		/// </summary>
		private void SetAliasTypes (string key, Enum enumAlias)
		{
			string[] names = Enum.GetNames (enumAlias.GetType ());
			int[] values = (int[])Enum.GetValues (enumAlias.GetType ());
			
			for (int i = 0; i < names.Length; i++)
			{
				AddAlias (key, names[i], values[i]);
			}
		}
#endif
		
		/// <summary>
		/// Returns a case insensitive hashtable.
		/// </summary>
		private Hashtable InsensitiveHashtable ()
		{
			return new Hashtable (CaseInsensitiveHashCodeProvider.Default, 
								  CaseInsensitiveComparer.Default);
		}
		#endregion
	}
}