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
using System.Globalization;
using Nini.Util;

namespace Nini.Config
{
	/// <include file='IniConfig.xml' path='//Class[@name="IniConfig"]/docs/*' />
	public class IniConfig : ConfigBase
	{
		#region Private variables
		IniConfigSource parent = null;
		#endregion
		
		#region Constructors
		/// <include file='IniConfig.xml' path='//Constructor[@name="Constructor"]/docs/*' />
		public IniConfig (string name, IConfigSource source)
			: base(name, source)
		{
			parent = (IniConfigSource)source;
		}
		#endregion

		#region Public properties
		#endregion

		#region Public methods
		/// <include file='IniConfig.xml' path='//Method[@name="Get"]/docs/*' />
		public override string Get (string key)
		{
			if (!parent.CaseSensitive) {
				key = CaseInsensitiveKeyName (key);
			}

			return base.Get (key);
		}

		/// <include file='IniConfig.xml' path='//Method[@name="Set"]/docs/*' />
		public override void Set (string key, object value)
		{
			if (!parent.CaseSensitive) {
				key = CaseInsensitiveKeyName (key);
			}

			base.Set (key, value);
		}
		
		/// <include file='IniConfig.xml' path='//Method[@name="Remove"]/docs/*' />
		public override void Remove (string key)
		{
			if (!parent.CaseSensitive) {
				key = CaseInsensitiveKeyName (key);
			}

			base.Remove (key);
		}
		#endregion

		#region Private methods
		/// <summary>
		/// Returns the key name if the case insensitivity is turned on.  
		/// </summary>
		private string CaseInsensitiveKeyName (string key)
		{
			string result = null;

			string lowerKey = key.ToLower ();
			foreach (string currentKey in keys.Keys)
			{
				if (currentKey.ToLower () == lowerKey) {
					result = currentKey;
					break;
				}
			}

			return (result == null) ? key : result;
		}
		#endregion
	}
}