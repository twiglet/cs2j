/*
   Copyright 2010,2011 Kevin Glynn (kevin.glynn@twigletsoftware.com)

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

   Author(s):

   Kevin Glynn (kevin.glynn@twigletsoftware.com)
*/

package CS2JNet.System.Text.RegularExpressions;

/**
 * @author keving
 *
 */
public enum RegexOptions {

	None,			//	Specifies that no options are set.
 	IgnoreCase,		//	Specifies case-insensitive matching.
 	Multiline,		//	Multiline mode. Changes the meaning of ^ and $ so they match at the beginning and end, respectively, of any line, and not just the beginning and end of the entire string.
 	ExplicitCapture,	//	Specifies that the only valid captures are explicitly named or numbered groups of the form (?<name>...). This allows unnamed parentheses to act as noncapturing groups without the syntactic clumsiness of the expression (?:...).
	Compiled,		//	Specifies that the regular expression is compiled to an assembly. This yields faster execution but increases startup time. This value should not be assigned to the Options property when calling the CompileToAssembly method.
 	Singleline,		//	Specifies single-line mode. Changes the meaning of the dot (.) so it matches every character (instead of every character except \n).
 	IgnorePatternWhitespace,	//	Eliminates unescaped white space from the pattern and enables comments marked with #. However, the IgnorePatternWhitespace value does not affect or eliminate white space in character classes.
 	RightToLeft,	//	Specifies that the search will be from right to left instead of from left to right.
 	ECMAScript,		//	Enables ECMAScript-compliant behavior for the expression. This value can be used only in conjunction with the IgnoreCase, Multiline, and Compiled values. The use of this value with any other values results in an exception.
 	CultureInvariant	//	Specifies that cultural differences in language is ignored. See Performing Culture-Insensitive Operations in the RegularExpressions Namespace for more information.
}
