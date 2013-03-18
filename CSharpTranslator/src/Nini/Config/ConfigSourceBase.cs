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
using System.Text;
using System.Collections;

namespace Nini.Config
{
	/// <include file='IConfigSource.xml' path='//Interface[@name="IConfigSource"]/docs/*' />
	public abstract class ConfigSourceBase : IConfigSource
	{
		#region Private variables
		ArrayList sourceList = new ArrayList ();
		ConfigCollection configList = null;
		bool autoSave = false;
		AliasText alias = new AliasText ();
		#endregion

		#region Constructors
		/// <include file='ConfigSourceBase.xml' path='//Constructor[@name="Constructor"]/docs/*' />
		public ConfigSourceBase ()
		{
			configList = new ConfigCollection (this);
		}
		#endregion
		
		#region Public properties
		/// <include file='IConfigSource.xml' path='//Property[@name="Configs"]/docs/*' />
		public ConfigCollection Configs
		{
			get { return configList; }
		}
		
		/// <include file='IConfigSource.xml' path='//Property[@name="AutoSave"]/docs/*' />
		public bool AutoSave
		{
			get { return autoSave; }
			set { autoSave = value; }
		}
		
		/// <include file='IConfigSource.xml' path='//Property[@name="Alias"]/docs/*' />
		public AliasText Alias
		{
			get { return alias; }
		}
		#endregion
		
		#region Public methods
		/// <include file='IConfigSource.xml' path='//Method[@name="Merge"]/docs/*' />
		public void Merge (IConfigSource source)
		{
			if (!sourceList.Contains (source))  {
				sourceList.Add (source);
			}
			
			foreach (IConfig config in source.Configs)
			{
				this.Configs.Add (config);
			}
		}
		
		/// <include file='IConfigSource.xml' path='//Method[@name="AddConfig"]/docs/*' />
		public virtual IConfig AddConfig (string name)
		{
			return configList.Add (name);
		}

		/// <include file='IConfigSource.xml' path='//Method[@name="GetExpanded"]/docs/*' />
		public string GetExpanded (IConfig config, string key)
		{
			return Expand (config, key, false);
		}
		
		/// <include file='IConfigSource.xml' path='//Method[@name="Save"]/docs/*' />
		public virtual void Save ()
		{
			OnSaved (new EventArgs ());
		}

		/// <include file='IConfigSource.xml' path='//Method[@name="Reload"]/docs/*' />
		public virtual void Reload ()
		{
			OnReloaded (new EventArgs ());
		}
		
		/// <include file='IConfigSource.xml' path='//Method[@name="ExpandKeyValues"]/docs/*' />
		public void ExpandKeyValues ()
		{
			string[] keys = null;

			foreach (IConfig config in configList)
			{
				keys = config.GetKeys ();
				for (int i = 0; i < keys.Length; i++)
				{
					Expand (config, keys[i], true);
				}
			}
		}

		/// <include file='IConfigSource.xml' path='//Method[@name="ReplaceKeyValues"]/docs/*' />
		public void ReplaceKeyValues ()
		{
			ExpandKeyValues ();
		}
		#endregion

		#region Public events
		/// <include file='IConfigSource.xml' path='//Event[@name="Reloaded"]/docs/*' />
		public event EventHandler Reloaded;

		/// <include file='IConfigSource.xml' path='//Event[@name="Saved"]/docs/*' />
		public event EventHandler Saved;
		#endregion

		#region Protected methods
		/// <include file='ConfigSourceBase.xml' path='//Method[@name="OnReloaded"]/docs/*' />
		protected void OnReloaded (EventArgs e)
		{
			if (Reloaded != null) {
				Reloaded (this, e);
			}
		}

		/// <include file='ConfigSourceBase.xml' path='//Method[@name="OnSaved"]/docs/*' />
		protected void OnSaved (EventArgs e)
		{
			if (Saved != null) {
				Saved (this, e);
			}
		}
		#endregion

		#region Private methods	
		/// <summary>
		/// Expands key values from the given IConfig.
		/// </summary>
		private string Expand (IConfig config, string key, bool setValue)
		{
			string result = config.Get (key);
			if (result == null) {
				throw new ArgumentException (String.Format ("[{0}] not found in [{1}]",
										key, config.Name));
			}

			while (true)
			{
				int startIndex = result.IndexOf ("${", 0);
				if (startIndex == -1) {
					break;
				}

				int endIndex = result.IndexOf ("}", startIndex + 2);
				if (endIndex == -1) {
					break;
				}

				string search = result.Substring (startIndex + 2, 
												  endIndex - (startIndex + 2));

				if (search == key) {
					// Prevent infinite recursion
					throw new ArgumentException 
						("Key cannot have a expand value of itself: " + key);
				}

				string replace = ExpandValue (config, search);

				result = result.Replace("${" + search + "}", replace);
			}

			if (setValue) {
				config.Set(key, result);
			}

			return result;
		}
		
		/// <summary>
		/// Returns the replacement value of a config.
		/// </summary>
		private string ExpandValue (IConfig config, string search)
		{
			string result = null;
			
			string[] replaces = search.Split ('|');
			
			if (replaces.Length > 1) {
				IConfig newConfig = this.Configs[replaces[0]];
				if (newConfig == null) {
					throw new ArgumentException ("Expand config not found: "
												 + replaces[0]);
				}
				result = newConfig.Get (replaces[1]);
				if (result == null) {
					throw new ArgumentException ("Expand key not found: "
												 + replaces[1]);
				}
			} else {
				result = config.Get (search);
				
				if (result == null) {
				    throw new ArgumentException ("Key not found: " + search);
				}
			}
			
			return result;
		}
		#endregion
	}
}
