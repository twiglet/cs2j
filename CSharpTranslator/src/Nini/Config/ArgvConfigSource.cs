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
using System.Text;
using System.Collections;
using Nini.Util;

namespace Nini.Config
{
	/// <include file='ArgvConfigSource.xml' path='//Class[@name="ArgvConfigSource"]/docs/*' />
	public class ArgvConfigSource : ConfigSourceBase
	{
		#region Private variables
		ArgvParser parser = null;
		string[] arguments = null;
		#endregion

		#region Constructors
		/// <include file='ArgvConfigSource.xml' path='//Constructor[@name="Constructor"]/docs/*' />
		public ArgvConfigSource (string[] arguments)
		{
			parser = new ArgvParser (arguments);
			this.arguments = arguments;
		}
		#endregion
		
		#region Public properties
		#endregion
		
		#region Public methods
		/// <include file='ArgvConfigSource.xml' path='//Method[@name="Save"]/docs/*' />
		public override void Save ()
		{
			throw new ArgumentException ("Source is read only");
		}

		/// <include file='ArgvConfigSource.xml' path='//Method[@name="Reload"]/docs/*' />
		public override void Reload ()
		{
			throw new ArgumentException ("Source cannot be reloaded");
		}
		
		/// <include file='ArgvConfigSource.xml' path='//Method[@name="AddSwitch"]/docs/*' />
		public void AddSwitch (string configName, string longName)
		{
			AddSwitch (configName, longName, null);
		}
		
		/// <include file='ArgvConfigSource.xml' path='//Method[@name="AddSwitchShort"]/docs/*' />
		public void AddSwitch (string configName, string longName, 
								string shortName)
		{
			IConfig config = GetConfig (configName);
			
			if (shortName != null && 
				(shortName.Length < 1 || shortName.Length > 2)) {
				throw new ArgumentException ("Short name may only be 1 or 2 characters");
			}

			// Look for the long name first
			if (parser[longName] != null) {
				config.Set (longName, parser[longName]);
			} else if (shortName != null && parser[shortName] != null) {
				config.Set (longName, parser[shortName]);
			}
		}
		
		/// <include file='ArgvConfigSource.xml' path='//Method[@name="GetArguments"]/docs/*' />
		public string[] GetArguments ()
		{
			string[] result = new string[this.arguments.Length];
			Array.Copy (this.arguments, 0, result, 0, this.arguments.Length);

			return result;
		}
		#endregion

		#region Private methods
		/// <summary>
		/// Returns an IConfig.  If it does not exist then it is added.
		/// </summary>
		private IConfig GetConfig (string name)
		{
			IConfig result = null;
			
			if (this.Configs[name] == null) {
				result = new ConfigBase (name, this);
				this.Configs.Add (result);
			} else {
				result = this.Configs[name];
			}
			
			return result;
		}
		#endregion
	}
}