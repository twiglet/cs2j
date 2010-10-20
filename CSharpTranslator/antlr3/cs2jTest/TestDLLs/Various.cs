using System;
namespace cs2jTest.Various.Features
{
	public class Various
	{
		public Various ()
		{
		}
		
		public string TestRWProperty {get; set;}
		
		public string get_TestRWProperty() {
			return "hello";
		}
		
		private string _testROProperty = null;
		public string TestROProperty {
			get { return _testROProperty; }
		}
		private string _testWOProperty = null;	
		public string TestWOProperty {
			set { _testWOProperty = value;}
		}
		
	}
}

