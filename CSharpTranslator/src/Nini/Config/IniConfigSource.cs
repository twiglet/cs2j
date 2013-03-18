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
using Nini.Ini;

namespace Nini.Config
{
	/// <include file='IniConfigSource.xml' path='//Class[@name="IniConfigSource"]/docs/*' />
	public class IniConfigSource : ConfigSourceBase
	{
		#region Private variables
		IniDocument iniDocument = null;
		string savePath = null;
		bool caseSensitive = true;
		#endregion
		
		#region Public properties
		#endregion

		#region Constructors
		/// <include file='IniConfigSource.xml' path='//Constructor[@name="Constructor"]/docs/*' />
		public IniConfigSource ()
		{
			iniDocument = new IniDocument ();
		}

		/// <include file='IniConfigSource.xml' path='//Constructor[@name="ConstructorPath"]/docs/*' />
		public IniConfigSource (string filePath)
		{
			Load (filePath);
		}
		
		/// <include file='IniConfigSource.xml' path='//Constructor[@name="ConstructorTextReader"]/docs/*' />
		public IniConfigSource (TextReader reader)
		{
			Load (reader);
		}

		/// <include file='IniConfigSource.xml' path='//Constructor[@name="ConstructorIniDocument"]/docs/*' />
		public IniConfigSource (IniDocument document)
		{
			Load (document);
		}
		
		/// <include file='IniConfigSource.xml' path='//Constructor[@name="ConstructorStream"]/docs/*' />
		public IniConfigSource (Stream stream)
		{
			Load (stream);
		}
		#endregion
		
		#region Public properties
		/// <include file='IniConfigSource.xml' path='//Property[@name="CaseSensitive"]/docs/*' />
		public bool CaseSensitive
		{
			get { return caseSensitive; }
			set { caseSensitive = value; }
		}

		/// <include file='IniConfigSource.xml' path='//Property[@name="SavePath"]/docs/*' />
		public string SavePath
		{
			get { return savePath; }
		}
		#endregion
		
		#region Public methods
		/// <include file='IniConfigSource.xml' path='//Method[@name="LoadPath"]/docs/*' />
		public void Load (string filePath)
		{
			Load (new StreamReader (filePath));
			this.savePath = filePath;
		}
		
		/// <include file='IniConfigSource.xml' path='//Method[@name="LoadTextReader"]/docs/*' />
		public void Load (TextReader reader)
		{
			Load (new IniDocument (reader));
		}

		/// <include file='IniConfigSource.xml' path='//Method[@name="LoadIniDocument"]/docs/*' />
		public void Load (IniDocument document)
		{
			this.Configs.Clear ();

			this.Merge (this); // required for SaveAll
			iniDocument = document;
			Load ();
		}
		
		/// <include file='IniConfigSource.xml' path='//Method[@name="LoadStream"]/docs/*' />
		public void Load (Stream stream)
		{
			Load (new StreamReader (stream));
		}

		/// <include file='IniConfigSource.xml' path='//Method[@name="Save"]/docs/*' />
		public override void Save ()
		{
			if (!IsSavable ()) {
				throw new ArgumentException ("Source cannot be saved in this state");
			}

			MergeConfigsIntoDocument ();
			
			iniDocument.Save (this.savePath);
			base.Save ();
		}
		
		/// <include file='IniConfigSource.xml' path='//Method[@name="SavePath"]/docs/*' />
		public void Save (string path)
		{
			this.savePath = path;
			this.Save ();
		}
		
		/// <include file='IniConfigSource.xml' path='//Method[@name="SaveTextWriter"]/docs/*' />
		public void Save (TextWriter writer)
		{
			MergeConfigsIntoDocument ();
			iniDocument.Save (writer);
			savePath = null;
			OnSaved (new EventArgs ());
		}

		/// <include file='IniConfigSource.xml' path='//Method[@name="SaveStream"]/docs/*' />
		public void Save (Stream stream)
		{
			MergeConfigsIntoDocument ();
			iniDocument.Save (stream);
			savePath = null;
			OnSaved (new EventArgs ());
		}

		/// <include file='IConfigSource.xml' path='//Method[@name="Reload"]/docs/*' />
		public override void Reload ()
		{
			if (savePath == null) {
				throw new ArgumentException ("Error reloading: You must have "
							+ "the loaded the source from a file");
			}

			iniDocument = new IniDocument (savePath);
			MergeDocumentIntoConfigs ();
			base.Reload ();
		}

		/// <include file='IniConfigSource.xml' path='//Method[@name="ToString"]/docs/*' />
		public override string ToString ()
		{
			MergeConfigsIntoDocument ();
			StringWriter writer = new StringWriter ();
			iniDocument.Save (writer);

			return writer.ToString ();
		}
		#endregion
		
		#region Private methods
		/// <summary>
		/// Merges all of the configs from the config collection into the 
		/// IniDocument before it is saved.  
		/// </summary>
		private void MergeConfigsIntoDocument ()
		{
			RemoveSections ();
			foreach (IConfig config in this.Configs)
			{
				string[] keys = config.GetKeys ();

				// Create a new section if one doesn't exist
				if (iniDocument.Sections[config.Name] == null) {
					IniSection section = new IniSection (config.Name);
					iniDocument.Sections.Add (section);
				}
				RemoveKeys (config.Name);

				for (int i = 0; i < keys.Length; i++)
				{
					iniDocument.Sections[config.Name].Set (keys[i], config.Get (keys[i]));
				}
			}
		}

		/// <summary>
		/// Removes all INI sections that were removed as configs.
		/// </summary>
		private void RemoveSections ()
		{
			IniSection section = null;
			for (int i = 0; i < iniDocument.Sections.Count; i++)
			{
				section = iniDocument.Sections[i];
				if (this.Configs[section.Name] == null) {
					iniDocument.Sections.Remove (section.Name);
				}
			}
		}

		/// <summary>
		/// Removes all INI keys that were removed as config keys.
		/// </summary>
		private void RemoveKeys (string sectionName)
		{
			IniSection section = iniDocument.Sections[sectionName];

			if (section != null) {
				foreach (string key in section.GetKeys ())
				{
					if (this.Configs[sectionName].Get (key) == null) {
						section.Remove (key);
					}
				}
			}
		}

		/// <summary>
		/// Loads the configuration file.
		/// </summary>
		private void Load ()
		{
			IniConfig config = null;
			IniSection section = null;
			IniItem item = null;

			for (int j = 0; j < iniDocument.Sections.Count; j++)
			{
				section = iniDocument.Sections[j];
				config = new IniConfig (section.Name, this);

				for (int i = 0; i < section.ItemCount; i++)
				{
					item = section.GetItem (i);
					
					if  (item.Type == IniType.Key) {
						config.Add (item.Name, item.Value);
					}
				}
				
				this.Configs.Add (config);
			}
		}

		/// <summary>
		/// Merges the IniDocument into the Configs when the document is 
		/// reloaded.  
		/// </summary>
		private void MergeDocumentIntoConfigs ()
		{
			// Remove all missing configs first
			RemoveConfigs ();

			IniSection section = null;
			for (int i = 0; i < iniDocument.Sections.Count; i++)
			{
				section = iniDocument.Sections[i];

				IConfig config = this.Configs[section.Name];
				if (config == null) {
					// The section is new so add it
					config = new ConfigBase (section.Name, this);
					this.Configs.Add (config);
				}				
				RemoveConfigKeys (config);
			}
		}

		/// <summary>
		/// Removes all configs that are not in the newly loaded INI doc.  
		/// </summary>
		private void RemoveConfigs ()
		{
			IConfig config = null;
			for (int i = this.Configs.Count - 1; i > -1; i--)
			{
				config = this.Configs[i];
				// If the section is not present in the INI doc
				if (iniDocument.Sections[config.Name] == null) {
					this.Configs.Remove (config);
				}
			}
		}

		/// <summary>
		/// Removes all INI keys that were removed as config keys.
		/// </summary>
		private void RemoveConfigKeys (IConfig config)
		{
			IniSection section = iniDocument.Sections[config.Name];

			// Remove old keys
			string[] configKeys = config.GetKeys ();
			foreach (string configKey in configKeys)
			{
				if (!section.Contains (configKey)) {
					// Key doesn't exist, remove
					config.Remove (configKey);
				}
			}

			// Add or set all new keys
			string[] keys = section.GetKeys ();
			for (int i = 0; i < keys.Length; i++)
			{
				string key = keys[i];
				config.Set (key, section.GetItem (i).Value);
			}
		}

		/// <summary>
		/// Returns true if this instance is savable.
		/// </summary>
		private bool IsSavable ()
		{
			return (this.savePath != null);
		}
		#endregion
	}
}