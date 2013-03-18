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

namespace Nini.Config
{
	/// <include file='IConfig.xml' path='//Interface[@name="IConfig"]/docs/*' />
	public interface IConfig
	{
		/// <include file='IConfig.xml' path='//Property[@name="ConfigSource"]/docs/*' />
		IConfigSource ConfigSource { get; }
		
		/// <include file='IConfig.xml' path='//Property[@name="Name"]/docs/*' />
		string Name { get; set; }
		
		/// <include file='IConfig.xml' path='//Property[@name="Alias"]/docs/*' />
		AliasText Alias { get; }

		/// <include file='IConfig.xml' path='//Method[@name="Contains"]/docs/*' />
		bool Contains (string key);

		/// <include file='IConfig.xml' path='//Method[@name="Get"]/docs/*' />
		string Get (string key);
		
		/// <include file='IConfig.xml' path='//Method[@name="GetDefault"]/docs/*' />
		string Get (string key, string defaultValue);

		/// <include file='IConfig.xml' path='//Method[@name="GetExpanded"]/docs/*' />
		string GetExpanded (string key);
		
		/// <include file='IConfig.xml' path='//Method[@name="Get"]/docs/*' />
		string GetString (string key);
		
		/// <include file='IConfig.xml' path='//Method[@name="GetDefault"]/docs/*' />
		string GetString (string key, string defaultValue);
		
		/// <include file='IConfig.xml' path='//Method[@name="GetInt"]/docs/*' />
		int GetInt (string key);
		
		/// <include file='IConfig.xml' path='//Method[@name="GetIntAlias"]/docs/*' />
		int GetInt (string key, bool fromAlias);
		
		/// <include file='IConfig.xml' path='//Method[@name="GetIntDefault"]/docs/*' />
		int GetInt (string key, int defaultValue);
		
		/// <include file='IConfig.xml' path='//Method[@name="GetIntDefaultAlias"]/docs/*' />
		int GetInt (string key, int defaultValue, bool fromAlias);
		
		/// <include file='IConfig.xml' path='//Method[@name="GetLong"]/docs/*' />
		long GetLong (string key);
		
		/// <include file='IConfig.xml' path='//Method[@name="GetLongDefault"]/docs/*' />
		long GetLong (string key, long defaultValue);
		
		/// <include file='IConfig.xml' path='//Method[@name="GetBoolean"]/docs/*' />
		bool GetBoolean (string key);
		
		/// <include file='IConfig.xml' path='//Method[@name="GetBooleanDefault"]/docs/*' />
		bool GetBoolean (string key, bool defaultValue);

		/// <include file='IConfig.xml' path='//Method[@name="GetFloat"]/docs/*' />
		float GetFloat (string key);

		/// <include file='IConfig.xml' path='//Method[@name="GetFloatDefault"]/docs/*' />
		float GetFloat (string key, float defaultValue);
		
		/// <include file='IConfig.xml' path='//Method[@name="GetDouble"]/docs/*' />
		double GetDouble (string key);

		/// <include file='IConfig.xml' path='//Method[@name="GetDoubleDefault"]/docs/*' />
		double GetDouble (string key, double defaultValue);
		
		/// <include file='IConfig.xml' path='//Method[@name="GetKeys"]/docs/*' />
		string[] GetKeys ();

		/// <include file='IConfig.xml' path='//Method[@name="GetValues"]/docs/*' />
		string[] GetValues ();
		
		/// <include file='IConfig.xml' path='//Method[@name="Set"]/docs/*' />
		void Set (string key, object value);
		
		/// <include file='IConfig.xml' path='//Method[@name="Remove"]/docs/*' />
		void Remove (string key);

		/// <include file='IConfig.xml' path='//Event[@name="KeySet"]/docs/*' />
		event ConfigKeyEventHandler KeySet;

		/// <include file='IConfig.xml' path='//Event[@name="KeyRemoved"]/docs/*' />
		event ConfigKeyEventHandler KeyRemoved;
	}
}