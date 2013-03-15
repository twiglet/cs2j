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
using System.IO;
using System.Collections;
using Microsoft.Win32;
using Nini.Ini;

namespace Nini.Config
{
	#region RegistryRecurse enumeration
	/// <include file='RegistryConfigSource.xml' path='//Enum[@name="RegistryRecurse"]/docs/*' />
	public enum RegistryRecurse
	{
		/// <include file='RegistryConfigSource.xml' path='//Enum[@name="RegistryRecurse"]/Value[@name="None"]/docs/*' />
		None,
		/// <include file='RegistryConfigSource.xml' path='//Enum[@name="RegistryRecurse"]/Value[@name="Flattened"]/docs/*' />
		Flattened,
		/// <include file='RegistryConfigSource.xml' path='//Enum[@name="RegistryRecurse"]/Value[@name="Namespacing"]/docs/*' />
		Namespacing
	}
	#endregion

	/// <include file='RegistryConfigSource.xml' path='//Class[@name="RegistryConfigSource"]/docs/*' />
	public class RegistryConfigSource : ConfigSourceBase
	{
		#region Private variables
		RegistryKey defaultKey = null;
		#endregion
		
		#region Public properties
		/// <include file='RegistryConfigSource.xml' path='//Property[@name="DefaultKey"]/docs/*' />
		public RegistryKey DefaultKey
		{
			get { return defaultKey; }
			set { defaultKey = value; }
		}
		#endregion

		#region Constructors
		#endregion
		
		#region Public methods
		/// <include file='RegistryConfigSource.xml' path='//Method[@name="AddConfig"]/docs/*' />
		public override IConfig AddConfig (string name)
		{
			if (this.DefaultKey == null) {
				throw new ApplicationException ("You must set DefaultKey");
			}

			return AddConfig (name, this.DefaultKey);
		}

		/// <include file='RegistryConfigSource.xml' path='//Method[@name="AddConfigKey"]/docs/*' />
		public IConfig AddConfig (string name, RegistryKey key)
		{
			RegistryConfig result = new RegistryConfig (name, this);
			result.Key = key;
			result.ParentKey = true;

			this.Configs.Add (result);

			return result;
		}

		/// <include file='RegistryConfigSource.xml' path='//Method[@name="AddMapping"]/docs/*' />
		public void AddMapping (RegistryKey registryKey, string path)
		{
			RegistryKey key = registryKey.OpenSubKey (path, true);
			
			if (key == null) {
				throw new ArgumentException ("The specified key does not exist");
			}
			
			LoadKeyValues (key, ShortKeyName (key));
		}
		
		/// <include file='RegistryConfigSource.xml' path='//Method[@name="AddMappingRecurse"]/docs/*' />
		public void AddMapping (RegistryKey registryKey, 
								string path, 
								RegistryRecurse recurse)
		{
			RegistryKey key = registryKey.OpenSubKey (path, true);
			
			if (key == null) {
				throw new ArgumentException ("The specified key does not exist");
			}
			
			if (recurse == RegistryRecurse.Namespacing) {
				LoadKeyValues (key, path);
			} else {
				LoadKeyValues (key, ShortKeyName (key));
			}
			
			string[] subKeys = key.GetSubKeyNames ();
			for (int i = 0; i < subKeys.Length; i++)
			{
				switch (recurse)
				{
				case RegistryRecurse.None:
					// no recursion
					break;
				case RegistryRecurse.Namespacing:
					AddMapping (registryKey, path + "\\" + subKeys[i], recurse);
					break;
				case RegistryRecurse.Flattened:
					AddMapping (key, subKeys[i], recurse);
					break;
				}
			}
		}
		
		/// <include file='IConfigSource.xml' path='//Method[@name="Save"]/docs/*' />
		public override void Save ()
		{
			MergeConfigsIntoDocument ();

			for (int i = 0; i < this.Configs.Count; i++)
			{
				// New merged configs are not RegistryConfigs
				if (this.Configs[i] is RegistryConfig) {
					RegistryConfig config = (RegistryConfig)this.Configs[i];
					string[] keys = config.GetKeys ();
					
					for (int j = 0; j < keys.Length; j++)
					{
						 config.Key.SetValue (keys[j], config.Get (keys[j]));
					}
				}
			}
		}

		/// <include file='IConfigSource.xml' path='//Method[@name="Reload"]/docs/*' />
		public override void Reload ()
		{
			ReloadKeys ();
		}
		#endregion
		
		#region Private methods
		/// <summary>
		/// Loads all values from the registry key.
		/// </summary>
		private void LoadKeyValues (RegistryKey key, string keyName)
		{
			RegistryConfig config = new RegistryConfig (keyName, this);
			config.Key = key;

			string[] values = key.GetValueNames ();
			foreach (string value in values)
			{
				config.Add (value, key.GetValue (value).ToString ());
			}
			this.Configs.Add (config);
		}

		/// <summary>
		/// Merges all of the configs from the config collection into the 
		/// registry.
		/// </summary>
		private void MergeConfigsIntoDocument ()
		{
			foreach (IConfig config in this.Configs)
			{
				if (config is RegistryConfig) {
					RegistryConfig registryConfig = (RegistryConfig)config;

					if (registryConfig.ParentKey) {
						registryConfig.Key = 
							registryConfig.Key.CreateSubKey (registryConfig.Name);
					}
					RemoveKeys (registryConfig);

					string[] keys = config.GetKeys ();
					for (int i = 0; i < keys.Length; i++)
					{
						registryConfig.Key.SetValue (keys[i], config.Get (keys[i]));
					}
					registryConfig.Key.Flush ();
				}
			}
		}

		/// <summary>
		/// Reloads all keys.
		/// </summary>
		private void ReloadKeys ()
		{
			RegistryKey[] keys = new RegistryKey[this.Configs.Count];

			for (int i = 0; i < keys.Length; i++)
			{
				keys[i] = ((RegistryConfig)this.Configs[i]).Key;
			}

			this.Configs.Clear ();
			for (int i = 0; i < keys.Length; i++)
			{
				LoadKeyValues (keys[i], ShortKeyName (keys[i]));
			}
		}

		/// <summary>
		/// Removes all keys not present in the current config.  
		/// </summary>
		private void RemoveKeys (RegistryConfig config)
		{
			foreach (string valueName in config.Key.GetValueNames ())
			{
				if (!config.Contains (valueName)) {
					config.Key.DeleteValue (valueName);
				}
			}
		}
		
		/// <summary>
		/// Returns the key name without the fully qualified path.
		/// e.g. no HKEY_LOCAL_MACHINE\\MyKey, just MyKey
		/// </summary>
		private string ShortKeyName (RegistryKey key)
		{
			int index = key.Name.LastIndexOf ("\\");

			return (index == -1) ? key.Name : key.Name.Substring (index + 1);
		}
		
		#region RegistryConfig class
		/// <summary>
		/// Registry Config class.
		/// </summary>
		private class RegistryConfig : ConfigBase
		{
			#region Private variables
			RegistryKey key = null;
			bool parentKey = false;
			#endregion

			#region Constructor
			/// <summary>
			/// Constructor.
			/// </summary>
			public RegistryConfig (string name, IConfigSource source)
				: base (name, source)
			{
			}
			#endregion

			#region Public properties
			/// <summary>
			/// Gets or sets whether the key is a parent key. 
			/// </summary>
			public bool ParentKey
			{
				get { return parentKey; }
				set { parentKey = value; }
			}

			/// <summary>
			/// Registry key for the Config.
			/// </summary>
			public RegistryKey Key
			{
				get { return key; }
				set { key = value; }
			}
			#endregion
		}
		#endregion

		#endregion
	}
}
